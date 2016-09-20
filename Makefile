all: cidata/meta-data cidata/user-data
	@true

cidata/user-data: cidata/user-data.template .ssh/ssh-container Makefile
	@cat "$<" | env CONTAINER_SSH_KEY="$(shell cat .ssh/ssh-container.pub)" envsubst '$$USER $$CONTAINER_SSH_KEY $$CACHE_VIP' | tee "$@.tmp"
	mv "$@.tmp" "$@"

.ssh/ssh-container:
	@mkdir -p $(shell dirname $@)
	@ssh-keygen -f $@ -P '' -C "vagrant@$(shell uname -n)"

key: .ssh/ssh-container
	@aws ec2 import-key-pair --key-name vagrant-$(shell md5 -q .ssh/ssh-container.pub) --public-key-material "$(shell cat .ssh/ssh-container.pub)"

cidata.iso: cidata/user-data cidata/meta-data
	mkisofs -R -V cidata -o $@.tmp cidata
	mv $@.tmp $@

cidata/meta-data: cidata/user-data Makefile
	@mkdir -p cidata
	@echo --- | tee $@.tmp
	@echo instance-id: $(shell basename $(shell pwd)) | tee -a $@.tmp
	mv $@.tmp $@
