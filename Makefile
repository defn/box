cidata.iso: cidata/user-data cidata/meta-data
	mkisofs -R -V cidata -o $@.tmp cidata
	mv $@.tmp $@

cidata/meta-data: cidata/user-data
	@mkdir -p cidata
	@echo --- | tee $@.tmp
	@echo instance-id: $(shell date +%s) | tee -a $@.tmp
	mv $@.tmp $@

cidata/user-data: cidata/user-data.template $(CACHE_DIR)/.ssh/ssh-vagrant
	@cat "$<" | env VAGRANT_SSH_KEY="$(shell cat $(CACHE_DIR)/.ssh/ssh-vagrant.pub)" envsubst '$$USER $$VAGRANT_SSH_KEY' | tee "$@.tmp"
	mv "$@.tmp" "$@"

$(CACHE_DIR)/.ssh/ssh-vagrant:
	@mkdir -p $(shell dirname $@)
	@ssh-keygen -f $@ -P ''

key:
	@aws ec2 import-key-pair --key-name vagrant-$(shell md5 -q $(CACHE_DIR)/.ssh/ssh-vagrant.pub) --public-key-material "$(shell cat $(CACHE_DIR)/.ssh/ssh-vagrant.pub)"
