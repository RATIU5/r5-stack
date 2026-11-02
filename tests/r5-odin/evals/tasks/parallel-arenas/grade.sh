cp "$TASK/setup/par/par_test.odin" par/par_test.odin
cp -R "$TASK/setup/drive/." drive/
odin test par -vet -strict-style > .odin-out.txt 2>&1 || exit 1
grep -q "leak" .odin-out.txt && exit 1
expected=$(python3 -I -c "
n = 500000
s = sum((j % 65536) ** 2 for j in range(n))
print(s * 32)")
odin build drive -out:drive_bin -o:speed -vet -strict-style > .build-out.txt 2>&1 || exit 1
python3 -I "$EVALS/measure.py" --timeout 60 --max-mb 600 --out .drive-out.txt -- ./drive_bin > .measure.json || exit 1
python3 -I "$EVALS/grade_drive.py" .measure.json .drive-out.txt equals sum "$expected" equals max 4294836225 equals count 16000000 min speedup_x100 120 max-rss x 300 > .grade.json || exit 1
odin build drive -out:drive_tsan -sanitize:thread -strict-style > .build-tsan-out.txt 2>&1 || exit 1
python3 -I "$EVALS/measure.py" --timeout 300 --max-mb 2000 --out .tsan-out.txt -- ./drive_tsan > .measure-tsan.json || exit 1
python3 -I "$EVALS/grade_drive.py" .measure-tsan.json .tsan-out.txt equals sum "$expected" absent x ThreadSanitizer > .grade-tsan.json
