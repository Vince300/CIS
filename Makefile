OUTPUT_FOLDER=provisioning

TAR_EXT=.tar.gz
TAR_ARGS=z
TARC=tar -c$(TAR_ARGS)f

WORKERD_DIR=worker-daemons
WORKERD_NAMES=config.ru config.yml worker.rb worker_dispatch.rb workerd.rb workerd_control.rb cisd.service worker
WORKERD_OUTPUT=$(OUTPUT_FOLDER)/workerd$(TAR_EXT)

FRONTEND_SCRIPTS_OUTPUT=$(OUTPUT_FOLDER)/frontend_scripts$(TAR_EXT)
FRONTEND_SCRIPTS_FILES=$(wildcard scripts/*)

FRONTEND_SERVERS_OUTPUT=$(OUTPUT_FOLDER)/frontend_servers$(TAR_EXT)
FRONTEND_SERVERS_FILES=$(wildcard frontend_servers/*) $(wildcard frontend_servers/localhost/*) \
	$(wildcard frontend_servers/machine/*)

ALL=$(WORKERD_OUTPUT) $(FRONTEND_SCRIPTS_OUTPUT) $(FRONTEND_SERVERS_OUTPUT)

all: $(ALL)

$(WORKERD_OUTPUT): $(WORKERD_NAMES:%=$(WORKERD_DIR)/%)
	$(TARC) "$@" $^

$(FRONTEND_SCRIPTS_OUTPUT): $(FRONTEND_SCRIPTS_FILES)
	$(TARC) "$@" $^

$(FRONTEND_SERVERS_OUTPUT): $(FRONTEND_SERVERS_FILES)
	$(TARC) "$@" $^

clean:
	rm -f $(ALL)

.PHONY: all clean