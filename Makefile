OUTPUT_FOLDER=provisioning

TAR_EXT=.tar.gz
TAR_ARGS=z
TARC=tar -c$(TAR_ARGS)f

WORKERD_DIR=worker-daemons
WORKERD_NAMES=config.ru config.yml worker.rb worker_dispatch.rb workerd.rb workerd_control.rb cisd.service
WORKERD_OUTPUT=$(OUTPUT_FOLDER)/workerd$(TAR_EXT)

all: $(WORKERD_OUTPUT)

$(WORKERD_OUTPUT): $(WORKERD_NAMES:%=$(WORKERD_DIR)/%)
	$(TARC) "$@" $^ 

clean:
	rm -f $(WORKERD_OUTPUT)

.PHONY: all clean