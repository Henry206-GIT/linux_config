CXX      = g++
CXXFLAGS = -std=c++17 -O2 -Wall -Wextra
LIBS     = -lncurses
BINDIR   = /home/henry/.config/hypr/CPP_Widget

.PHONY: all clean

all: clock clock-sec

clock: hypr-clock.cpp
	$(CXX) $(CXXFLAGS) -o $(BINDIR)/clock hypr-clock.cpp $(LIBS)

clock-sec: hypr-clock.cpp
	$(CXX) $(CXXFLAGS) -DMIT_SEKUNDEN -o $(BINDIR)/clock-sec hypr-clock.cpp $(LIBS)

clean:
	rm -f $(BINDIR)/clock $(BINDIR)/clock-sec
