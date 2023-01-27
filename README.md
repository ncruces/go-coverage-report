# Go coverage report

GitHub Action to add a coverage report and badge to your Go repo.

Apply it to your repo by adding this step your one of your workflows:

```yaml
    - name: Update coverage report
      uses: ncruces/go-coverage-report
```

Your repository needs to have a Wiki for the Action to work.

You should run this step _after_ your tests run (it will fail if tests fail),
and only for _one platform_ (don't do it in a matrix).

This Action will add generate an HTML report and SVG badge,
and save them as "hidden" files in your Wiki.

You can then apply them to your README.md with this Markdown snippet:

```markdown
[![Go Coverage](https://github.com/USER/REPO/wiki/coverage.svg)](https://raw.githack.com/wiki/USER/REPO/coverage.html)
```