build_debug:
	swift build -c debug

build_release:
	swift build -c release

run_tests:
	swift test -q

clean:
	rm -rf .build
