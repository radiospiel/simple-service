.PHONY: test

test:
	rspec

.PHONY: doc
doc: todo
	rm -rf doc/*
	yard doc -o doc - TODO.txt

todo:
	lentil . -f comp | tee TODO.txt
