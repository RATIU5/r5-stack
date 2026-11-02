odin test kinds -vet -strict-style > .odin-out.txt 2>&1 && ! grep -q "leak" .odin-out.txt && ! grep -q "switch" kinds/kinds.odin
