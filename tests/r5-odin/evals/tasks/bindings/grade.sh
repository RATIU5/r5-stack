cc -c lib/vec.c -o lib/vec.o && ar rcs lib/libvec.a lib/vec.o && odin test bind -vet -strict-style > .odin-out.txt 2>&1 && ! grep -q "leak" .odin-out.txt
