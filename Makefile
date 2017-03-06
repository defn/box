key: $(BLOCK_PATH)/base/.ssh/ssh-container
	@aws ec2 import-key-pair --key-name vagrant-$(shell md5sum --tag $<.pub | awk '{print $$4}') --public-key-material "$(shell cat $<.pub)"
