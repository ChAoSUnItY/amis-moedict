run ::
	gulp run

dev ::
	gulp dev

build ::
	gulp build

deps ::
	npm i
	gulp build

js/deps.js ::
	gulp webpack:build
	cp js/deps.js amis-deploy/js

manifest :: js/deps.js
	perl -pi -e 's/# [A-Z].*\n/# @{[`date`]}/m' manifest.appcache

upload ::
	rsync -avzP main.* view.* styles.css index.html js moe0:code/
	rsync -avzP main.* view.* styles.css index.html js moe1:code/

amis-static:
	cp -r styles.css *.html js css fonts p m s dict-amis*.json amis-deploy/
	cp ../amis-safolu/txt/amis-ch-mapping.json amis-deploy/s/ch-mapping.json
	cp ../amis-safolu/tmp/amis-stem-words.json amis-deploy/s/stem-words.json

amis ::
	@-git clone --depth 1 https://github.com/miaoski/amis-data.git moedict-data-amis
	cd moedict-data-amis && make moedict
	ln -sf moedict-data-amis/dict-amis.json   dict-amis.json
	node json2prefix.js p
	node autolink.js p > p.txt
	perl link2pack.pl p < p.txt
	cp moedict-data-amis/index.json           p/index.json
	cd moedict-data-amis && python cmn-amis-longstr.py
	cp moedict-data-amis/revdict-amis*.txt    p/

amis-poinsot ::
	@-git clone --depth 1 https://github.com/miaoski/amis-francais.git moedict-data-amis-mp
	cd moedict-data-amis-mp && python moedict.py
	ln -sf moedict-data-amis-mp/dict-amis-mp.json   dict-amis-mp.json
	node json2prefix.js m
	node autolink.js m > m.txt
	perl link2pack.pl m < m.txt
	cp moedict-data-amis-mp/index.json         m/index.json
	touch m/revdict-amis-def.txt
	touch m/revdict-amis-ex.txt

amis-safolu ::
	@-git clone --depth 1 https://github.com/miaoski/amis-safolu.git ../amis-safolu
	ln -sf ../amis-safolu/txt/dict-amis-safolu.json dict-amis-safolu.json
	node json2prefix.js s
	node autolink.js s > s.txt
	perl link2pack.pl s < s.txt
	cp ../amis-safolu/txt/index.json           s/index.json
	python ../amis-safolu/txt/revdict.py
	mv revdict-*.txt                           s/
	cp ../amis-safolu/txt/amis-ch-mapping.json s/ch-mapping.json
	ruby ../amis-safolu/txt/stem-mapping.rb
	cp ../amis-safolu/tmp/amis-stem-words.json s/stem-words.json

checkout ::
	-git clone --depth 1 https://github.com/g0v/moedict-data.git
	-git clone --depth 1 https://github.com/g0v/moedict-data-twblg.git
	-git clone --depth 1 https://github.com/g0v/moedict-data-hakka.git
	-git clone --depth 1 https://github.com/g0v/moedict-data-csld.git
	-git clone --depth 1 https://github.com/miaoski/amis-data.git moedict-data-amis
	-git clone https://github.com/g0v/moedict-epub.git

moedict-data :: checkout pinyin

offline :: deps
	perl link2pack.pl a < a.txt
	perl link2pack.pl t < t.txt
	perl link2pack.pl h < h.txt
	-perl link2pack.pl c < c.txt
	perl special2pack.pl

offline-dev :: moedict-data deps translation
	ln -fs ../moedict-data/dict-revised-translated.json moedict-epub/dict-revised.json
	cd moedict-epub && perl json2unicode.pl             > dict-revised.unicode.json
	cd moedict-epub && perl json2unicode.pl sym-pua.txt > dict-revised.pua.json
	ln -fs moedict-epub/dict-revised.unicode.json          dict-revised.unicode.json
	ln -fs moedict-epub/dict-revised.pua.json              dict-revised.pua.json
	ln -fs moedict-data-twblg/dict-twblg.json              dict-twblg.json
	ln -fs moedict-data-twblg/dict-twblg-ext.json          dict-twblg-ext.json
	ln -fs moedict-data-hakka/dict-hakka.json              dict-hakka.json
	ln -fs moedict-data-csld/dict-csld.json                dict-csld.json
	cd moedict-data-amis && python moedict.py
	ln -fs moedict-data-amis/dict-amis.json                dict-amis.json
	#node json2prefix.js a
	#node autolink.js a | env LC_ALL=C sort > a.txt
	perl link2pack.pl a < a.txt
	#node json2prefix.js t
	#node autolink.js t | env LC_ALL=C sort > t.txt
	perl link2pack.pl t < t.txt
	#node json2prefix.js h
	#node autolink.js h | env LC_ALL=C sort > h.txt
	perl link2pack.pl h < h.txt
	#-node json2prefix.js c
	#-node autolink.js c > c.txt
	-perl link2pack.pl c < c.txt
	node json2prefix.js p
	node autolink.js p > p.txt
	perl link2pack.pl p < p.txt
	cp moedict-data-amis/index.json                        p/index.json
	perl special2pack.pl

csld ::
	python translation-data/csld2json.py
	cp translation-data/csld-translation.json dict-csld.json
	node json2prefix.js c
	node autolink.js c | env LC_ALL=C sort > c.txt
	perl link2pack.pl c < c.txt
	cp moedict-data-csld/index.json c/

hakka ::
	node json2prefix.js h
	node autolink.js h | env LC_ALL=C sort > h.txt
	perl link2pack.pl h < h.txt

twblg ::
	node json2prefix.js t
	node autolink.js t > t.txt
	perl link2pack.pl t < t.txt
	python twblg_index.py

pinyin ::
	perl build-pinyin-lookup.pl a
	perl build-pinyin-lookup.pl t
	perl build-pinyin-lookup.pl h
	perl build-pinyin-lookup.pl c

translation :: translation-data moedict-data
	python translation-data/xml2txt.py
	python translation-data/txt2json.py
	cp translation-data/moe-translation.json moedict-data/dict-revised-translated.json

translation-data :: translation-data/handedict.txt translation-data/cedict.txt translation-data/cfdict.xml

translation-data/handedict.txt :
	cd translation-data && curl http://www.handedict.de/handedict/handedict-20110528.tar.bz2 | tar -Oxvj -f - handedict-20110528/handedict_nb.u8 > handedict.txt

translation-data/cedict.txt :
	cd translation-data && curl http://www.mdbg.net/chindict/export/cedict/cedict_1_0_ts_utf-8_mdbg.txt.gz | gunzip > cedict.txt

translation-data/cfdict.xml :
	cd translation-data && curl -O 'http://www.chine-informations.com/chinois/open/CFDICT/cfdict_xml.zip' && unzip -o cfdict_xml.zip && rm cfdict_xml.zip

clean-translation-data ::
	rm -f translation-data/cfdict.xml translation-data/cedict.txt translation-data/handedict.txt

all :: data/0/100.html
	tar jxf data.tar.bz2

clean ::
	git clean -xdf

emulate ::
	make -C cordova emulate
