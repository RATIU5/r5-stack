odin test calc -vet -strict-style > .odin-out.txt 2>&1 && ! grep -q "leak" .odin-out.txt && [ "$(grep -c '//' calc/calc.odin)" = 1 ]
