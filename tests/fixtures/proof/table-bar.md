# A bar inside a table cell

## The table

Each row has three cells. The third cell of the first row holds a bar inside a code span, and the third cell of the second row holds a bar written with a backslash.

| # | Step | Done when |
|---|---|---|
| 1 | Count the failures | `bash tests/run.sh | grep -c FAIL` prints 0 |
| 2 | Write a bar in a cell | a \| b |
| 3 | Leave the other rows alone | fine |
