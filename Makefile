.PHONY: test

test:
	rspec

.PHONY: doc
doc:
	rm -rf doc/*
	yard doc -o doc
