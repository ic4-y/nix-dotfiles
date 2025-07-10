# Guide: Creating Pull Requests with GitHub CLI (`gh`)

This document outlines the process for creating GitHub Pull Requests (PRs) directly from the command line using the GitHub CLI (`gh`). This method streamlines the workflow for developers by integrating PR management into their terminal environment.

## 1. Prerequisites

Before you begin, ensure you have the following:

1.  **GitHub CLI Installed**: If not already installed, download and install the GitHub CLI from [https://cli.github.com/](https://cli.github.com/).
2.  **Authenticated GitHub CLI**: Authenticate the CLI with your GitHub account by running `gh auth login` in your terminal and following the on-screen prompts.
3.  **Repository Context**: Ensure your terminal is currently in the root directory of your local Git repository (e.g., `/home/ap/Coding/nix/nix-dotfiles`).

## 2. Workflow Steps

### Step 1: Ensure Local Branch is Pushed

Your local changes must be pushed to the remote repository before you can create a PR.

- **Check your current branch**:

  ```bash
  git status
  ```

  Ensure you are on your feature branch (e.g., `feature/disko-impermanence`).

- **Push the branch to the remote**:
  ```bash
  git push origin <your-feature-branch-name>
  ```
  Replace `<your-feature-branch-name>` with the actual name of your branch (e.g., `feature/disko-impermanence`). If this is the first time pushing the branch, you might need to set the upstream:
  ```bash
  git push --set-upstream origin <your-feature-branch-name>
  ```

### Step 2: Create the Pull Request

Use the `gh pr create` command to initiate the PR creation process.

- **Basic Command**:

  ```bash
  gh pr create --base <base-branch> --head <feature-branch> --title "<PR Title>" --body "<PR Description>"
  ```

- **Example**:
  Assuming your base branch is `main` and your feature branch is `feature/disko-impermanence`, with a specific title and body:

  ```bash
  gh pr create --base main --head feature/disko-impermanence --title "feat: Implement and document Disko VM testing" --body "This PR introduces the Disko VM testing library and documentation. It includes fixes for missing arguments and module imports, ensuring the tests pass and providing a guide for integration into other projects."
  ```

- **Command Breakdown**:
  - `--base <base-branch>`: Specifies the branch into which you want to merge your changes (e.g., `main`, `master`).
  - `--head <feature-branch>`: Specifies the branch containing your changes (e.g., `feature/disko-impermanence`).
  - `--title "<PR Title>"`: Sets the title for your pull request. Make it descriptive.
  - `--body "<PR Description>"`: Provides a description for the PR. This is where you can detail the changes, link to issues, and explain the context.

### Step 3: Follow Prompts and Configure

The `gh pr create` command may prompt you for additional details if they are not provided via flags, such as:

- **Assignees**: You can assign specific users to review the PR.
- **Labels**: Add relevant labels (e.g., `bug`, `feature`, `documentation`).
- **Milestones**: Assign the PR to a project milestone.

You can also add these details later via the GitHub web interface or additional `gh` commands (e.g., `gh pr edit`).

### Step 4: Review, Merge, and Clean Up

Once the PR is created:

1.  **Review**: Your assigned reviewers will examine the code and provide feedback.
2.  **Address Feedback**: If changes are requested, make them on your local feature branch, commit them, and push them again:
    ```bash
    git add .
    git commit -m "Refactor: Address review comments on Disko testing"
    git push origin <your-feature-branch-name>
    ```
3.  **Merge**: After approval, you or a designated person can merge the PR through the GitHub web interface or using `gh pr merge`.
4.  **Delete Local Branch**: Once the PR is merged and the changes are integrated into the main branch, you can safely delete your local feature branch.
    ```bash
    # Ensure you are not on the branch you want to delete
    git checkout main
    # Delete the local branch
    git branch -d feature/disko-impermanence
    ```
    _(Note: Replace `feature/disko-impermanence` with your actual branch name.)_

## 3. Conclusion

Using the GitHub CLI for PR creation streamlines the development workflow by keeping you in the terminal. It's an efficient way to manage your contributions and collaborate with your team.
