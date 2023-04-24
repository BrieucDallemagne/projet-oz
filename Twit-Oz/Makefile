TWEETS_FOLDER="tweets"
TEST_FOLDER="tweets-test"
UNAME_S := $(shell uname -s)
ENTRY_POINT=main.ozf

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
	$(OZENGINE) $(ENTRY_POINT) --folder $(TWEETS_FOLDER)

testrun: $(ENTRY_POINT) 
	$(OZENGINE) $(ENTRY_POINT) --folder $(TEST_FOLDER)

pickle:
	rm -f Pickle/Word/*.ozp

user:
	rm -f User/*.txt

clean : pickle user
	rm -f *.ozf

.PHONY: clean pickle user
