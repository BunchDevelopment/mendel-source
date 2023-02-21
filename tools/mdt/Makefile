all: deb wheel

deb:
	dpkg-buildpackage -tc --no-sign

wheel:
	python3 setup.py sdist bdist_wheel

upload: wheel
	python3 -m twine upload dist/*

clean:
	rm -rf debian/mdt/ dist/ build/ mdt.egg-info/ __pycache__/

.PHONY: all deb wheel upload-wheel upload-deb clean
