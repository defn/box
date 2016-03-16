cidata.iso: cidata/user-data cidata/meta-data
	mkisofs -R -V cidata -o $@.tmp cidata
	mv $@.tmp $@

cidata/meta-data: .ssh/ssh-vagrant
	@echo --- | tee $@.tmp
	@echo instance-id: vagrant-$(shell date +%s) | tee -a $@.tmp
	mv $@.tmp $@

cidata/user-data: .ssh/ssh-vagrant
	libexec/gen-user-data > cidata/user-data.tmp
	mv cidata/user-data.tmp cidata/user-data

.ssh/ssh-vagrant:
	@ssh-keygen -f .ssh/ssh-vagrant -P ''
