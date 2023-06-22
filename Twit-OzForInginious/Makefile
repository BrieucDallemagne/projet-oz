TWEETS_FOLDER="tweets"
TEST_FOLDER="tweets-test"
UNAME_S := $(shell uname -s)
ENTRY_POINT=main.ozf

#Flags set to True for features; type XXX=false while doing make run to disable the XXX flag for example
NGRAM=true
SAVE=true
RANDOM=true
NBTHREAD=16


ifeq ($(UNAME_S),Darwin)
	OZC = /Applications/Mozart2.app/Contents/Resources/bin/ozc
	OZENGINE = /Applications/Mozart2.app/Contents/Resources/bin/ozengine
else
	OZC = ozc
	OZENGINE = ozengine
endif

all : $(ENTRY_POINT)

%.ozf: %.oz
	$(OZC) -c $< -o "$@"

run: $(ENTRY_POINT) 
	$(OZENGINE) $(ENTRY_POINT) --folder $(TWEETS_FOLDER) --nbthread $(NBTHREAD)

testrun: $(ENTRY_POINT) 
	$(OZENGINE) $(ENTRY_POINT) --folder $(TEST_FOLDER)

pickle:
	rm -f Pickle/Word/*.ozp

user:
	rm -f User/*.txt

clean : pickle user
	rm -f *.ozf

folder:
	mkdir -p Pickle/Word
	mkdir Users

.PHONY: clean pickle user
