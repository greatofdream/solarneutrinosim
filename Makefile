.PHONY: all
all: gs98.mod.pdf as09.mod.pdf mb22.mod.pdf
# filename %.zams, %.mod are set in inlist_$*_pms, inlist_$*_zams

%.zams:
	mkdir -p LOGS_$*_pms photos_$*_pms
	ln -s inlist_$*_pms inlist_project
	ln -s profile_columns_pms.list profile_columns.list
	ln -s LOGS_$*_pms LOGS
	ln -s photos_$*_pms photos
	./rn
	rm LOGS photos inlist_project profile_columns.list

%.model: %.zams
	mkdir -p LOGS_$*_zams photos_$*_zams
	ln -s inlist_$*_zams inlist_project
	ln -s profile_columns_ms.list profile_columns.list
	ln -s LOGS_$*_zams LOGS
	ln -s photos_$*_zams photos
	./rn
	rm LOGS photos inlist_project profile_columns.list

%.mod.pdf: %.model
	python3 preview.py -m $* -o $@

.SECONDARY:
