cp "$TASK/setup/store/store_test.odin" store/store_test.odin
cp -R "$TASK/setup/drive/." drive/
odin test store -vet -strict-style > .odin-out.txt 2>&1 || exit 1
grep -q "leak" .odin-out.txt && exit 1
odin build drive -out:drive_bin -o:speed -vet -strict-style > .build-out.txt 2>&1 || exit 1
python3 -I "$EVALS/measure.py" --timeout 60 --max-mb 400 --out .drive-out.txt -- ./drive_bin > .measure.json || exit 1
python3 -I "$EVALS/grade_drive.py" .measure.json .drive-out.txt equals corrupt 0 max failed_adds 0 max allocations 100 max live 0 max-rss x 64 > .grade.json
