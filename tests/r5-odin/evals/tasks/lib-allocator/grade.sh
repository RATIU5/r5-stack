odin test textutil -vet -strict-style > .odin-out.txt 2>&1 && ! grep -q "leak" .odin-out.txt
