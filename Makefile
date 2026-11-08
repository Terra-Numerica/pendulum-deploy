.ONESHELL:

replication.pdf: REPLICATION.md
	pandoc $< \
		-o $@ \
		--pdf-engine=xelatex \
		--no-highlight \
		-s
