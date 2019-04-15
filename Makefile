################################################################################
# Project configuration (edit if you add directories)
################################################################################

# Patterns to exclude folders from the project's source
PROJ_SRC_EXCLUDES += \
. \
./.git% \
./asf4% \

# List the subdirectories for Atmel source and header files
ATMEL_SRC_DIRS :=  \
asf4 \
asf4/hpl/systick \
asf4/hpl/dmac \
asf4/hal/src \
asf4/samd21a/gcc \
asf4/hpl/pm \
asf4/hpl/sysctrl \
asf4/hal/utils/src \
asf4/examples \
asf4/hpl/gclk \
asf4/samd21a/gcc/gcc \
asf4/hpl/core

ATMEL_INCLUDE_DIRS := \
asf4 \
asf4/config \
asf4/examples \
asf4/hal/include \
asf4/hal/utils/include  \
asf4/hpl/core  \
asf4/hpl/dmac  \
asf4/hpl/gclk  \
asf4/hpl/pm  \
asf4/hpl/port  \
asf4/hpl/sysctrl  \
asf4/hpl/systick  \
asf4/hri  \
asf4/CMSIS/Include  \
asf4/samd21a/include 

################################################################################
# Make configuration.
################################################################################

# Top-level directories make should look for things in
vpath %.c src/ asf4/
vpath %.s src/ asf4/
vpath %.S src/ asf4/

############# Misc configuration #############
OUTPUT_FILE_NAME := Project
OUTPUT_FOLDER := build

############# Device configuration #############
# not sure if changing these will work
DEVICE_LINKER_SCRIPT := asf4/samd21a/gcc/gcc/samd21j18a_flash.ld
MCPU := cortex-m0plus
DEVICE_FLAG := __SAMD21J18A__

################################################################################
# Variable generation. Do not edit unless you know what you're doing!
################################################################################

# Platform specific makedir command.
ifdef SystemRoot
	SHELL = cmd.exe
	MK_DIR = mkdir
else
	ifeq ($(shell uname), Linux)
		MK_DIR = mkdir -p
	endif

	ifeq ($(shell uname | cut -d _ -f 1), CYGWIN)
		MK_DIR = mkdir -p
	endif

	ifeq ($(shell uname | cut -d _ -f 1), MINGW32)
		MK_DIR = mkdir -p
	endif

	ifeq ($(shell uname | cut -d _ -f 1), MINGW64)
		MK_DIR = mkdir -p
	endif
endif

# Platform specific output folder
ifdef SystemRoot
	OUTPUT_FOLDER_PATH = $(OUTPUT_FOLDER)$(shell echo \)
else
	OUTPUT_FOLDER_PATH = ./$(OUTPUT_FOLDER)/
endif

# Find the project source folders and remove those matching PROJ_SRC_EXCLUDES
ifdef SystemRoot
	SHELL = cmd.exe
	ROOT = $(shell chdir)
	ALL_PROJ_DIRS_WIN += $(shell dir /b/s/a:d)
	ALL_PROJ_DIRS = $(subst \,/,$(subst $(ROOT),.,$(ALL_PROJ_DIRS_WIN)))
	PROJ_SRC_DIRS_NIX += $(filter-out $(PROJ_SRC_EXCLUDES),$(ALL_PROJ_DIRS))
	PROJ_SRC_DIRS += $(subst /,\,$(subst ./,,$(PROJ_SRC_DIRS_NIX)))
else
	ALL_PROJ_DIRS += $(shell find . -type d)
	PROJ_SRC_DIRS += $(filter-out $(PROJ_SRC_EXCLUDES),$(ALL_PROJ_DIRS))
endif
$(info Project source directories: ${PROJ_SRC_DIRS})
# Find all source files in the directories
ALL_SRC_DIRS := $(PROJ_SRC_DIRS) $(ATMEL_SRC_DIRS)
SRC  := $(foreach dr, $(ALL_SRC_DIRS), $(wildcard $(dr)/*.[cS]))
# Create all names of all corresponding object files
OBJS := $(addsuffix .o,$(basename $(SRC)))
OBJS_AS_ARGS := $(foreach ob, $(OBJS), "$(ob)")
# Create all names of all corresponding dependency files
DEPS := $(OBJS:%.o=%.d)
DEPS_AS_ARGS := $(foreach dep, $(DEPS), "$(dep)")
# List the include files as linker args
ALL_INCLUDE_DIRS := $(PROJ_SRC_DIRS) $(ATMEL_INCLUDE_DIRS)
INCLUDE_DIRS_AS_FLAGS := $(foreach dir, $(ALL_INCLUDE_DIRS), -I"$(dir)")

# Outputs
OUTPUT_FILE_PATH += $(OUTPUT_FOLDER_PATH)$(OUTPUT_FILE_NAME)
$(shell $(MK_DIR) $(OUTPUT_FOLDER_PATH))

################################################################################
# Makefile targets. Do not edit unless you know what you're doing!
################################################################################
QUOTE := "


# All Target
all: $(ALL_DIRS) $(OUTPUT_FILE_PATH)

# Linker target

$(OUTPUT_FILE_PATH): $(OBJS)
	@echo Building target: $@
	@echo Invoking: ARM/GNU Linker
		$(QUOTE)arm-none-eabi-gcc$(QUOTE) -o $(OUTPUT_FILE_PATH).elf $(OBJS_AS_ARGS) \
		-Wl,--start-group -lm -Wl,--end-group -mthumb \
		-Wl,-Map="$(OUTPUT_FILE_PATH).map" --specs=nano.specs -Wl,--gc-sections -mcpu=$(MCPU) \
	 	$(INCLUDE_DIRS_AS_FLAGS) \
		-T"$(DEVICE_LINKER_SCRIPT)" \
		-L"$(basename $(DEVICE_LINKER_SCRIPT))"
	@echo Finished building target: $@

	"arm-none-eabi-objcopy" -O binary "$(OUTPUT_FILE_PATH).elf" "$(OUTPUT_FILE_PATH).bin"
	"arm-none-eabi-objcopy" -O ihex -R .eeprom -R .fuse -R .lock -R .signature  \
        "$(OUTPUT_FILE_PATH).elf" "$(OUTPUT_FILE_PATH).hex"
	"arm-none-eabi-objcopy" -j .eeprom --set-section-flags=.eeprom=alloc,load --change-section-lma \
        .eeprom=0 --no-change-warnings -O binary "$(OUTPUT_FILE_PATH).elf" \
        "$(OUTPUT_FILE_PATH).eep" || exit 0
	"arm-none-eabi-objdump" -h -S "$(OUTPUT_FILE_PATH).elf" > "$(OUTPUT_FILE_PATH).lss"
	"arm-none-eabi-size" "$(OUTPUT_FILE_PATH).elf"



# Compiler targets

%.o: %.c
	@echo Building .c file: $<
	@echo ARM/GNU C Compiler
	$(QUOTE)arm-none-eabi-gcc$(QUOTE) -x c -mthumb -DDEBUG -Os -ffunction-sections -mlong-calls -g3 -Wall -c -std=gnu99 \
		-D$(DEVICE_FLAG) -mcpu=$(MCPU)  \
		$(INCLUDE_DIRS_AS_FLAGS) \
		-MD -MP -MF "$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -MT"$(@:%.o=%.o)"  -o "$@" "$<"
	@echo Finished building: $<

%.o: %.s
	@echo Building .s file: $<
	@echo ARM/GNU Assembler
	$(QUOTE)arm-none-eabi-as$(QUOTE) -x c -mthumb -DDEBUG -Os -ffunction-sections -mlong-calls -g3 -Wall -c -std=gnu99 \
		-D$(DEVICE_FLAG) -mcpu=$(MCPU)  \
		$(INCLUDE_DIRS_AS_FLAGS) \
		-MD -MP -MF "$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -MT"$(@:%.o=%.o)"  -o "$@" "$<"
	@echo Finished building: $<

%.o: %.S
	@echo Building .S file: $<
	@echo ARM/GNU Preprocessing Assembler
	$(QUOTE)arm-none-eabi-gcc$(QUOTE) -x c -mthumb -DDEBUG -Os -ffunction-sections -mlong-calls -g3 -Wall -c -std=gnu99 \
		-D$(DEVICE_FLAG) -mcpu=$(MCPU)  \
		$(INCLUDE_DIRS_AS_FLAGS) \
		-MD -MP -MF "$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -MT"$(@:%.o=%.o)"  -o "$@" "$<"
	@echo Finished building: $<

# Detect changes in the dependent files and recompile the respective object files.
ifneq ($(MAKECMDGOALS),clean)
ifneq ($(strip $(DEPS)),)
-include $(DEPS)
endif
endif

$(ALL_DIRS):
	$(MK_DIR) "$@"

clean:
	rm -f $(OBJS_AS_ARGS)
	rm -f $(wildcard $(OUTPUT_FOLDER_PATH)*)
	rm -f $(DEPS_AS_ARGS)
