

release:
	@mush build --release
	@git add .
	@git commit -am "Release"
	@git push

test-local:
	@mush run

test-secrets:
	@bash tests/secrets-test.sh