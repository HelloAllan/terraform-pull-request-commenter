# Terraform Pull Request Commenter

> This project was forked from <https://github.com/robburger/terraform-pr-commenter> project, originally created by [
Rob Burger](https://github.com/robburger).

Adds opinionated comments to PR's based on Terraform `fmt`, `init`, `plan` and `validate` outputs.

## CURRENTLY WORK IN PROGRESS

## Summary

This Docker-based GitHub Action is designed to work in tandem with [hashicorp/setup-terraform](https://github.com/hashicorp/setup-terraform) with the **wrapper enabled**, taking the output from a `fmt`, `init`, `plan` or `validate`, formatting it and adding it to a pull request. Any previous comments from this Action are removed to keep the PR timeline clean.

> The `terraform_wrapper` needs to be set to `true` (which is already the default) for the `hashicorp/setup-terraform` step as it enables the capturing of `stdout`, `stderr` and the `exitcode`.

Support (for now) is [limited to Linux](https://help.github.com/en/actions/creating-actions/about-actions#types-of-actions) as Docker-based GitHub Actions can only be used on Linux runners.

## Usage

This action can only be run after a Terraform `fmt`, `init`, `plan` or `validate` has completed, and the output has been captured. For large outputs (especially from `plan`), it's recommended to write the output to a file first:

```yaml
- name: Terraform Plan
  id: plan
  run: |
    terraform plan -out workspace.plan > plan.txt

- name: Save plan output to file
  run: |
    echo "${{ steps.plan.outputs.output }}" > plan_output.txt

- name: Comment on PR
  uses: your-org/terraform-pull-request-commenter@v1
  with:
    commenter_type: plan
    input_file: plan_output.txt
    commenter_exitcode: ${{ steps.plan.outputs.exitcode }}
```

For smaller outputs, you can use the output directly:

```yaml
- name: Terraform Format
  id: fmt
  run: terraform fmt -check -recursive
  continue-on-error: true

- name: Post Format
  if: always() && github.ref != 'refs/heads/master' && (steps.fmt.outcome == 'success' || steps.fmt.outcome == 'failure')
  uses: sheeeng/terraform-pull-request-commenter@v1
  with:
    commenter_type: fmt
    commenter_input: ${{ format('{0}{1}', steps.fmt.outputs.stdout, steps.fmt.outputs.stderr) }}
    commenter_exitcode: ${{ steps.fmt.outputs.exitcode }}
```

### Inputs

| Name                 | Requirement | Description                                                       |
| -------------------- | ----------- | ----------------------------------------------------------------- |
| `commenter_type`     | _required_  | The type of comment. Options: [`fmt`, `init`, `plan`, `validate`] |
| `input_file`         | _required_  | The path to the file containing the comment to post.               |
| `commenter_exitcode` | _required_  | The exit code from a previous step output.                        |

### Environment Variables

| Name                     | Requirement | Description                                                                                                                                               |
| ------------------------ | ----------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `GITHUB_TOKEN`           | _required_  | Used to execute API calls. The `${{ secrets.GITHUB_TOKEN }}` already has permissions, but if you're using your own token, ensure it has the `repo` scope. |
| `TF_WORKSPACE`           | _optional_  | Default: `default`. This is used to separate multiple comments on a pull request in a matrix run.                                                         |
| `EXPAND_SUMMARY_DETAILS` | _optional_  | Default: `true`. This controls whether the comment output is collapsed or not.                                                                            |
| `HIGHLIGHT_CHANGES`      | _optional_  | Default: `true`. This switches `~` to `!` in `plan` diffs to highlight Terraform changes in orange. Set to `false` to disable.                            |

All of these environment variables can be set at `job` or `step` level. For example, you could collapse all outputs but expand on a `plan`:

```yaml
jobs:
  terraform:
    name: 'Terraform'
    runs-on: ubuntu-latest
    env:
      EXPAND_SUMMARY_DETAILS: 'false' # All steps will have this environment variable
    steps:
      - name: Checkout
        uses: actions/checkout@v2
...
      - name: Post Plan
        uses: sheeeng/terraform-pull-request-commenter@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          EXPAND_SUMMARY_DETAILS: 'true' # Override global environment variable; expand details just for this step
        with:
          commenter_type: plan
          commenter_input: ${{ format('{0}{1}', steps.plan.outputs.stdout, steps.plan.outputs.stderr) }}
          commenter_exitcode: ${{ steps.plan.outputs.exitcode }}
...
```

## Examples

Single workspace build, full example:

```yaml
name: 'Terraform'

on:
  pull_request:
  push:
    branches:
      - master

jobs:
  terraform:
    name: 'Terraform'
    runs-on: ubuntu-latest
    env:
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      TF_IN_AUTOMATION: true
    steps:
      - name: Checkout
        uses: actions/checkout@v2

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v1
        with:
          cli_config_credentials_token: ${{ secrets.TF_API_TOKEN }}
          terraform_version: 0.15.0

      - name: Terraform Format
        id: fmt
        run: terraform fmt -check -recursive
        continue-on-error: true

      - name: Post Format
        if: always() && github.ref != 'refs/heads/master' && (steps.fmt.outcome == 'success' || steps.fmt.outcome == 'failure')
        uses: sheeeng/terraform-pull-request-commenter@v1
        with:
          commenter_type: fmt
          commenter_input: ${{ format('{0}{1}', steps.fmt.outputs.stdout, steps.fmt.outputs.stderr) }}
          commenter_exitcode: ${{ steps.fmt.outputs.exitcode }}

      - name: Terraform Init
        id: init
        run: terraform init

      - name: Post Init
        if: always() && github.ref != 'refs/heads/master' && (steps.init.outcome == 'success' || steps.init.outcome == 'failure')
        uses: sheeeng/terraform-pull-request-commenter@v1
        with:
          commenter_type: init
          commenter_input: ${{ format('{0}{1}', steps.init.outputs.stdout, steps.init.outputs.stderr) }}
          commenter_exitcode: ${{ steps.init.outputs.exitcode }}

      - name: Terraform Validate
        id: validate
        run: terraform validate

      - name: Post Validate
        if: always() && github.ref != 'refs/heads/master' && (steps.validate.outcome == 'success' || steps.validate.outcome == 'failure')
        uses: sheeeng/terraform-pull-request-commenter@v1
        with:
          commenter_type: validate
          commenter_input: ${{ format('{0}{1}', steps.validate.outputs.stdout, steps.validate.outputs.stderr) }}
          commenter_exitcode: ${{ steps.validate.outputs.exitcode }}

      - name: Terraform Plan
        id: plan
        run: terraform plan -out workspace.plan

      - name: Post Plan
        if: always() && github.ref != 'refs/heads/master' && (steps.plan.outcome == 'success' || steps.plan.outcome == 'failure')
        uses: sheeeng/terraform-pull-request-commenter@v1
        with:
          commenter_type: plan
          commenter_input: ${{ format('{0}{1}', steps.plan.outputs.stdout, steps.plan.outputs.stderr) }}
          commenter_exitcode: ${{ steps.plan.outputs.exitcode }}

      - name: Terraform Apply
        id: apply
        if: github.ref == 'refs/heads/master' && github.event_name == 'push'
        run: terraform apply workspace.plan
```

Multi-workspace matrix/parallel build:

```yaml
...
jobs:
  terraform:
    name: 'Terraform'
    runs-on: ubuntu-latest
    strategy:
      matrix:
        workspace: [audit, staging]
    env:
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      TF_IN_AUTOMATION: true
      TF_WORKSPACE: ${{ matrix['workspace'] }}
    steps:
      - name: Checkout
        uses: actions/checkout@v2

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v1
        with:
          cli_config_credentials_token: ${{ secrets.TF_API_TOKEN }}
          terraform_version: 0.15.0

      - name: Terraform Init - ${{ matrix['workspace'] }}
        id: init
        run: terraform init

      - name: Post Init - ${{ matrix['workspace'] }}
        if: always() && github.ref != 'refs/heads/master' && (steps.init.outcome == 'success' || steps.init.outcome == 'failure')
        uses: sheeeng/terraform-pull-request-commenter@v1
          with:
            commenter_type: init
            commenter_input: ${{ format('{0}{1}', steps.init.outputs.stdout, steps.init.outputs.stderr) }}
            commenter_exitcode: ${{ steps.init.outputs.exitcode }}

      - name: Terraform Plan - ${{ matrix['workspace'] }}
        id: plan
        run: terraform plan -out ${{ matrix['workspace'] }}.plan

      - name: Post Plan - ${{ matrix['workspace'] }}
        if: always() && github.ref != 'refs/heads/master' && (steps.plan.outcome == 'success' || steps.plan.outcome == 'failure')
        uses: sheeeng/terraform-pull-request-commenter@v1
        with:
          commenter_type: plan
          commenter_input: ${{ format('{0}{1}', steps.plan.outputs.stdout, steps.plan.outputs.stderr) }}
          commenter_exitcode: ${{ steps.plan.outputs.exitcode }}
...
```

"What's the crazy-looking `if:` doing there?" Good question! It's broken into 3 logic groups separated by `&&`, so all need to return `true` for the step to run:

1. `always()` - ensures that the step is run regardless of the outcome in any previous steps. i.e. We don't want the build to quit after the previous step before we can write a PR comment with the failure reason.
2. `github.ref != 'refs/heads/master'` - prevents the step running on a `master` branch. PR comments are not possible when there's no PR!
3. `(steps.step_id.outcome == 'success' || steps.step_id.outcome == 'failure')` - ensures that this step only runs when `step_id` has either a `success` or `failed` outcome.

In English: "Always run this step, but only on a pull request and only when the previous step succeeds or fails...and then stop the build."

## Screenshots

### `fmt`

![fmt](images/fmt-output.png)

### `init`

![fmt](images/init-output.png)

### `plan`

![fmt](images/plan-output.png)

### `validate`

![fmt](images/validate-output.png)

## Troubleshooting & Contributing

Feel free to head over to the [Issues](https://github.com/sheeeng/terraform-pull-request-commenter/issues) tab to see if the issue you're having has already been reported. If not, [open a new one](https://github.com/sheeeng/terraform-pull-request-commenter/issues/new) and be sure to include as much relevant information as possible, including code-samples, and a description of what you expect to be happening.

## License

[MIT](LICENSE)
