---
title: How to create a blog like this
description: This is a guide to using the Chirpy Jekyll theme to create a personal blog like this
author: hoan9x
date: 2024-09-28 19:00:00 +0700
categories: [Personal blog, Chirpy Jekyll theme]
---

## 1. About GitHub Pages

This blog uses the [GitHub Pages](https://pages.github.com) feature which allows you to host static web pages directly from your GitHub repository. You can find all information about GitHub Pages features [here](https://docs.github.com/en/pages/getting-started-with-github-pages/about-github-pages#about-github-pages).

Please read the [usage limits](https://docs.github.com/en/pages/getting-started-with-github-pages/about-github-pages#usage-limits) section carefully and consider whether the GitHub Pages feature is suitable for you.

> This guide is for Windows users only, and there are many other ways to create a blog like this.<br>
> Please refer to the official guide [here](https://chirpy.cotes.page/posts/getting-started) to use the Chirpy Jekyll theme to create your blog.<br>
> You should find the most suitable way for yourself, and this is the way I find suitable for myself.
{: .prompt-warning }

## 2. Preparation

- GitHub account: You can go to [github.com](https://github.com) to **Sign up**, or **Sign in** if you already have an account.
- Choose a suitable and memorable **username** for your GitHub account: Because your final blog will have a domain in the format `http(s)://<username>.github.io`, so the username is quite important.

![Desktop View][img_1]{: width="800" height="420" .normal }
> You can change **username** in your account settings.
{: .prompt-info }

- Install [Docker Desktop](https://www.docker.com/products/docker-desktop).

> Docker is a virtual environment, where you can write posts and review your blog locally before publishing it.

- Install [Visual Studio Code (VSCode)](https://code.visualstudio.com/download) and the [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension.

> If you don't know how to install extensions for VSCode, please refer [here](https://code.visualstudio.com/docs/editor/extension-marketplace).

## 3. Step by step to create a blog like this

### 3.1. Step 1: Fork your own copy from repository [Chirpy Jekyll theme](https://github.com/cotes2020/jekyll-theme-chirpy).

![Desktop View][img_2]{: width="800" height="420" .normal }
![Desktop View][img_3]{: width="800" height="420" .normal }

Enter `Repository name` in the format `<username>.github.io`, replacing `username` with your GitHub username.<br>
This will be the domain name of the blog when it is hosted.<br>
After forking the repository, we'll configure a few more steps so that GitHub Pages can build and deploy automatically.

![Desktop View][img_4]{: width="800" height="420" .normal }

Go to the `Settings` of the repository you just forked. Click `Pages`.<br>
Choose Build and deployment Source is `GitHub Actions`.

![Desktop View][img_5]{: width="800" height="420" .normal }

Go to the `Actions` of your repository. Click `I understand...enable them`.

### 3.2. Step 2: Clone and setup docker environment.

Copy your URL to clone the repository.

![Desktop View][img_6]{: width="800" height="420" .normal }

Open VSCode and press the shortcut `Ctrl+Shift+P`;<br>
Then enter command `Dev Containers: Clone Repository in Container Volume...`.

![Desktop View][img_7]{: width="800" height="420" .normal }

Paste your repository URL and wait for the environment setup to complete.

![Desktop View][img_8]{: width="800" height="420" .normal }

> To be able to clone the repository in Container Volume, make sure that Docker engine is running
{: .prompt-warning }

![Desktop View][img_9]{: width="800" height="420" .normal }
> _Open Docker Desktop to check if the engine is running._

![Desktop View][img_10]{: width="800" height="420" .normal }
> _When Docker engine is not running, this error will be returned._

If everything goes well, you will see VSCode is cloning your repository

![Desktop View][img_11]{: width="800" height="420" .normal }

Please wait until the environment is completely setup.

![Desktop View][img_12]{: width="800" height="420" .normal }

### 3.3. Step 3: Publish your first initialize page.

Open new terminal.

![Desktop View][img_13]{: width="800" height="420" .normal }

Run `bash ./tools/init.sh` in your terminal.

![Desktop View][img_14]{: width="800" height="420" .normal }

The `init.sh` process will initialize your repository to default.

![Desktop View][img_15]{: width="800" height="420" .normal }

After initialization, push all files to github.

![Desktop View][img_16]{: width="800" height="420" .normal }
> After entering the command `git push -f origin master`.<br>
> VSCode may pop up a window asking you to log in to your GitHub account.<br>
> Please log in to be able to push the source code to your repository.
{: .prompt-warning }

After a successful push, you can open your browser to GitHub Actions to see the progress.

![Desktop View][img_17]{: width="800" height="420" .normal }

The successful build and deployment process will look like this:

![Desktop View][img_18]{: width="800" height="420" .normal }

Once you reach this step, your blog is hosted and accessible to everyone around the world.<br>
You can use any browser to access the domain `<username>.github.io` to see the result.

![Desktop View][img_19]{: width="800" height="420" .normal }

Of course your blog page is blank now, you need to put your information to configure the blog page.

### 3.4. Step 4: Configure your personal information.

Open and update the variables in the `_config.yml `file to add personalization to your blog page.

![Desktop View][img_20]{: width="800" height="420" .normal }

Please refer to the official guide to update the `_config.yml ` file [here](https://chirpy.cotes.page/posts/getting-started/#configuration).<br>
Or you can refer to my `_config.yml` file for this blog [here](https://github.com/hoan9x/hoan9x.github.io/blob/master/_config.yml).

### 3.5. Step 5: Write a 'Hello World!' post and review it on the localhost.

Please refer to the official guide for writing a new post [here](https://chirpy.cotes.page/posts/write-a-new-post).

![Desktop View][img_21]{: width="800" height="420" .normal }

Once you have a new post, open the terminal and run the command `bash ./tools/run.sh`.<br>
The above command will launch your blog on the address `http://127.0.0.1:4000`.

![Desktop View][img_22]{: width="800" height="420" .normal }

You can use your browser to access `http://127.0.0.1:4000` to review it.

![Desktop View][img_23]{: width="800" height="420" .normal }
![Desktop View][img_24]{: width="800" height="420" .normal }

### 3.6. Step 6: Push 'Hello World!' post to GitHub repository for global access.

Before pushing a post to the repository, use the following command `bash ./tools/test.sh` to test your post.

![Desktop View][img_25]{: width="800" height="420" .normal }

A successful test command will look like this:

![Desktop View][img_26]{: width="800" height="420" .normal }

If the test command has any errors, read the error information and correct it.<br>
To push the post to the GitHub repository, use the following commands:<br>
+ `git add *`
+ `git -n -m "<write some notes>"`
  + For example: `git -n -m "post hello world"` or `git -n -m "posted Aug2024"`
+ `git push`

After a successful push, you can open your browser to see the result.

![Desktop View][img_27]{: width="800" height="420" .normal }
![Desktop View][img_28]{: width="800" height="420" .normal }
![Desktop View][img_29]{: width="800" height="420" .normal }

### 3.7. Appendix: How to delete installed Docker environment.

Click on the bottom left corner of VSCode `Dev Container:...` to `Close Remote Connection`.

![Desktop View][img_30]{: width="800" height="420" .normal }
![Desktop View][img_31]{: width="800" height="420" .normal }

If you want to go back to the remote repository to edit files or write posts, click as shown below:

![Desktop View][img_32]{: width="800" height="420" .normal }

And if you want to delete the local repository you cloned, the docker environment you installed;<br>
Open Docker Desktop and delete _Containers_, _Images_, _Volumes_, _Builds_ one by one as shown below:

![Desktop View][img_33]{: width="800" height="420" .normal }
![Desktop View][img_34]{: width="800" height="420" .normal }
![Desktop View][img_35]{: width="800" height="420" .normal }
![Desktop View][img_36]{: width="800" height="420" .normal }

The above deletion actions only delete the source code and environment on your local machine. You can start again from [Step 2: Clone and setup docker environment](#step-2-clone-and-setup-docker-environment) to reinstall the local environment. If you want to delete your blog that is hosted on the global network, please delete GitHub Pages according to [this article](https://docs.github.com/en/pages/getting-started-with-github-pages/deleting-a-github-pages-site).

[//]: # (----------SCOPE OF DECLARATION OF LIST OF IMAGES USED IN POST----------)
[img_1]: /assets/img/2024-09-create-blog-like-this/01_change_username.png "Change username in account settings"
[img_2]: /assets/img/2024-09-create-blog-like-this/02_fork_chirpy_jekyll_theme.png "Fork theme"
[img_3]: /assets/img/2024-09-create-blog-like-this/03_create_fork_repo.png "Enter name and create fork"
[img_4]: /assets/img/2024-09-create-blog-like-this/04_settings_pages_github_action.png "Settings pages"
[img_5]: /assets/img/2024-09-create-blog-like-this/05_enable_workflows_github_action.png "Enable workflows"
[img_6]: /assets/img/2024-09-create-blog-like-this/06_copy_url_of_repo.png "Copy URL of repo"
[img_7]: /assets/img/2024-09-create-blog-like-this/07_clone_repo_to_container_volume.png "Clone repo to container volume"
[img_8]: /assets/img/2024-09-create-blog-like-this/08_enter_url_repo_to_clone.png "Enter URL repo to clone"
[img_9]: /assets/img/2024-09-create-blog-like-this/09_make_sure_docker_engine_running.png "Make sure Docker engine running"
[img_10]: /assets/img/2024-09-create-blog-like-this/10_error_when_docker_not_running.png "Error when Docker not running"
[img_11]: /assets/img/2024-09-create-blog-like-this/11_wait_connecting_repo.png "Wait connecting repo"
[img_12]: /assets/img/2024-09-create-blog-like-this/12_setup_env_done.png "Setup done"
[img_13]: /assets/img/2024-09-create-blog-like-this/13_open_terminal.png "Open terminal"
[img_14]: /assets/img/2024-09-create-blog-like-this/14_bash_init.png "Bash init"
[img_15]: /assets/img/2024-09-create-blog-like-this/15_init_success.png "Init success"
[img_16]: /assets/img/2024-09-create-blog-like-this/16_git_push.png "Git push"
[img_17]: /assets/img/2024-09-create-blog-like-this/17_check_github_action_running.png "Check GitHub action running"
[img_18]: /assets/img/2024-09-create-blog-like-this/18_check_github_action_done.png "When GitHub action done"
[img_19]: /assets/img/2024-09-create-blog-like-this/19_init_pages.png "Review init pages"
[img_20]: /assets/img/2024-09-create-blog-like-this/20_config_yml.png "Config .yml file"
[img_21]: /assets/img/2024-09-create-blog-like-this/21_write_hello_world_blog.png "Write hello world blog"
[img_22]: /assets/img/2024-09-create-blog-like-this/22_run_blog_in_local.png "Run blog in local"
[img_23]: /assets/img/2024-09-create-blog-like-this/23_review_blog_in_local.png "Review blog in local"
[img_24]: /assets/img/2024-09-create-blog-like-this/24_review_hello_world_blog_local.png "Review hello world blog local"
[img_25]: /assets/img/2024-09-create-blog-like-this/25_test_pages_before_post.png "Test pages before post"
[img_26]: /assets/img/2024-09-create-blog-like-this/26_test_pages_success.png "Test pages success"
[img_27]: /assets/img/2024-09-create-blog-like-this/27_check_github_action.png "Check GitHub action"
[img_28]: /assets/img/2024-09-create-blog-like-this/28_review_page_update_in_web.png "Review pages update in web"
[img_29]: /assets/img/2024-09-create-blog-like-this/29_review_hello_world_post.png "Review hello world post"
[img_30]: /assets/img/2024-09-create-blog-like-this/30_close_remote_dev_vscode.png "Close remove VSCode"
[img_31]: /assets/img/2024-09-create-blog-like-this/31_close_remote_dev_vscode.png "Close remove"
[img_32]: /assets/img/2024-09-create-blog-like-this/32_remote_dev_vscode_again.png "Remote env again"
[img_33]: /assets/img/2024-09-create-blog-like-this/33_delete_container.png "Delete container"
[img_34]: /assets/img/2024-09-create-blog-like-this/34_delete_image.png "Delete image"
[img_35]: /assets/img/2024-09-create-blog-like-this/35_delete_volumes.png "Delete volumes"
[img_36]: /assets/img/2024-09-create-blog-like-this/36_delete_builds.png "Delete builds"
