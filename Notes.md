#  cross compile for arm64
```
./configure --host=arm64-apple-macos11 --prefix=(pwd)/build --host=x86_64-apple-macos
```

# directory structure
root
 \- repositories (downloaded tarball or git repo)
 \- working (extracted files or git checkout)
 \- products (built things)
    \- both/shared/static
      \- package-name
        \- arch-name (x86_64 arm64 universal)


package folder name
package-version-tag's hash

always run autogen.sh or autoreconf to generate new sh
