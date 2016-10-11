all: cidata.iso
	@true

cidata/user-data: ../provision/cidata/user-data-vagrant.template ../provision/.ssh/ssh-container Makefile
	@cat "$<" | env CONTAINER_SSH_KEY="$(shell cat ../provision/.ssh/ssh-container.pub)" envsubst '$$USER $$CONTAINER_SSH_KEY $$CACHE_VIP' | tee "$@.tmp"
	mv "$@.tmp" "$@"

key: ../provision/.ssh/ssh-container
	@aws ec2 import-key-pair --key-name vagrant-$(shell md5 -q ../provision/.ssh/ssh-container.pub) --public-key-material "$(shell cat ../provision/.ssh/ssh-container.pub)"

cidata.iso: cidata/user-data cidata/meta-data
	mkisofs -R -V cidata -o $@.tmp cidata
	mv $@.tmp $@

cidata/meta-data: cidata/user-data Makefile
	@mkdir -p cidata
	@echo --- | tee $@.tmp
	@echo instance-id: $(shell basename $(shell pwd)) | tee -a $@.tmp
	mv $@.tmp $@
