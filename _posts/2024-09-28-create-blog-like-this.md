---
title: How to create a blog like this
description: This is a guide to using the Chirpy Jekyll theme to create a personal blog like this
author: hoan9x
date: 2024-09-28 19:00:00 +0700
categories: [Personal blog, Chirpy Jekyll theme]
---

## **About GitHub Pages**

---

This blog uses the [GitHub Pages](https://pages.github.com) feature which allows you to host static web pages directly from your GitHub repository. You can find all information about GitHub Pages features [here](https://docs.github.com/en/pages/getting-started-with-github-pages/about-github-pages#about-github-pages).

Please read the [usage limits](https://docs.github.com/en/pages/getting-started-with-github-pages/about-github-pages#usage-limits) section carefully and consider whether the GitHub Pages feature is suitable for you.

> This guide is for Windows users only, and there are many other ways to create a blog like this.<br>
> Please refer to the official guide [here](https://chirpy.cotes.page/posts/getting-started) to use the Chirpy Jekyll theme to create your blog.<br>
> You should find the most suitable way for yourself, and this is the way I find suitable for myself.
{: .prompt-warning }

## **Preparation**

---

- GitHub account: You can go to [github.com](https://github.com) to **Sign up**, or **Sign in** if you already have an account.
- Choose a suitable and memorable **username** for your GitHub account: Because your final blog will have a domain in the format `http(s)://<username>.github.io`, so the username is quite important.

![Docker Desktop](/assets/img/2024-09-create-blog-like-this/01_change_username.png){: width="600" height="315" .normal }
> You can change **username** in your account settings.
{: .prompt-info }

- Install [Docker Desktop](https://www.docker.com/products/docker-desktop).

> Docker is a virtual environment, where you can write posts and review your blog locally before publishing it.

- Install [Visual Studio Code (VSCode)](https://code.visualstudio.com/download) and the [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension.

> If you don't know how to install extensions for VSCode, please refer [here](https://code.visualstudio.com/docs/editor/extension-marketplace).

## **Step by step to create a blog like this**

---

### **Step 1: Fork your own copy from repository [Chirpy Jekyll theme](https://github.com/cotes2020/jekyll-theme-chirpy).**

![Desktop View](/assets/img/2024-09-create-blog-like-this/02_fork_chirpy_jekyll_theme.png){: width="600" height="315" .normal }
![Desktop View](/assets/img/2024-09-create-blog-like-this/03_create_fork_repo.png){: width="600" height="315" .normal }

Enter `Repository name` in the format `<username>.github.io`, replacing `username` with your GitHub username.<br>
This will be the domain name of the blog when it is hosted.<br>
After forking the repository, we'll configure a few more steps so that GitHub Pages can build and deploy automatically.

![Desktop View](/assets/img/2024-09-create-blog-like-this/04_settings_pages_github_action.png){: width="600" height="315" .normal }

Go to the `Settings` of the repository you just forked. Click `Pages`.<br>
Choose Build and deployment Source is `GitHub Actions`.

![Desktop View](/assets/img/2024-09-create-blog-like-this/05_enable_workflows_github_action.png){: width="600" height="315" .normal }

Go to the `Actions` of your repository. Click `I understand...enable them`.

---

### **Step 2: Clone and setup docker environment.**

Copy your URL to clone the repository.

![Desktop View](/assets/img/2024-09-create-blog-like-this/06_copy_url_of_repo.png){: width="600" height="315" .normal }

Open VSCode and press the shortcut `Ctrl+Shift+P`;<br>
Then enter command `Dev Containers: Clone Repository in Container Volume...`.

![Desktop View](/assets/img/2024-09-create-blog-like-this/07_clone_repo_to_container_volume.png){: width="600" height="315" .normal }

Paste your repository URL and wait for the environment setup to complete.

![Desktop View](/assets/img/2024-09-create-blog-like-this/08_enter_url_repo_to_clone.png){: width="600" height="315" .normal }

> To be able to clone the repository in Container Volume, make sure that Docker engine is running
{: .prompt-warning }

![Desktop View](/assets/img/2024-09-create-blog-like-this/09_make_sure_docker_engine_running.png){: width="600" height="315" .normal }
> _Open Docker Desktop to check if the engine is running._

![Desktop View](/assets/img/2024-09-create-blog-like-this/10_error_when_docker_not_running.png){: width="600" height="315" .normal }
> _When Docker engine is not running, this error will be returned._

If everything goes well, you will see VSCode is cloning your repository

![Desktop View](/assets/img/2024-09-create-blog-like-this/11_wait_connecting_repo.png){: width="600" height="315" .normal }

Please wait until the environment is completely setup.

![Desktop View](/assets/img/2024-09-create-blog-like-this/12_setup_env_done.png){: width="600" height="315" .normal }

---

### **Step 3: Publish your first initialize page.**

Open new terminal.

![Desktop View](/assets/img/2024-09-create-blog-like-this/13_open_terminal.png){: width="600" height="315" .normal }

Run `bash ./tools/init.sh` in your terminal.

![Desktop View](/assets/img/2024-09-create-blog-like-this/14_bash_init.png){: width="600" height="315" .normal }

The `init.sh` process will initialize your repository to default.

![Desktop View](/assets/img/2024-09-create-blog-like-this/15_init_success.png){: width="600" height="315" .normal }

After initialization, push all files to github.

![Desktop View](/assets/img/2024-09-create-blog-like-this/16_git_push.png){: width="600" height="315" .normal }
> After entering the command `git push -f origin master`.<br>
> VSCode may pop up a window asking you to log in to your GitHub account.<br>
> Please log in to be able to push the source code to your repository.
{: .prompt-warning }

After a successful push, you can open your browser to GitHub Actions to see the progress.

![Desktop View](/assets/img/2024-09-create-blog-like-this/17_check_github_action_running.png){: width="600" height="315" .normal }

The successful build and deployment process will look like this:

![Desktop View](/assets/img/2024-09-create-blog-like-this/18_check_github_action_done.png){: width="600" height="315" .normal }

Once you reach this step, your blog is hosted and accessible to everyone around the world.<br>
You can use any browser to access the domain `<username>.github.io` to see the result.

![Desktop View](/assets/img/2024-09-create-blog-like-this/19_init_pages.png){: width="600" height="315" .normal }

Of course your blog page is blank now, you need to put your information to configure the blog page.

---

### **Step 4: Configure your personal information.**

Open and update the variables in the `_config.yml `file to add personalization to your blog page.

![Desktop View](/assets/img/2024-09-create-blog-like-this/20_config_yml.png){: width="600" height="315" .normal }

Please refer to the official guide to update the `_config.yml ` file [here](https://chirpy.cotes.page/posts/getting-started/#configuration).<br>
Or you can refer to my `_config.yml` file for this blog [here](https://github.com/hoan9x/hoan9x.github.io/blob/master/_config.yml).

---

### **Step 5: Write a 'Hello World!' post and review it on the localhost.**

Please refer to the official guide for writing a new post [here](https://chirpy.cotes.page/posts/write-a-new-post).

![Desktop View](/assets/img/2024-09-create-blog-like-this/21_write_hello_world_blog.png){: width="600" height="315" .normal }

Once you have a new post, open the terminal and run the command `bash ./tools/run.sh`.<br>
The above command will launch your blog on the address `http://127.0.0.1:4000`.

![Desktop View](/assets/img/2024-09-create-blog-like-this/22_run_blog_in_local.png){: width="600" height="315" .normal }

You can use your browser to access `http://127.0.0.1:4000` to review it.

![Desktop View](/assets/img/2024-09-create-blog-like-this/23_review_blog_in_local.png){: width="600" height="315" .normal }
![Desktop View](/assets/img/2024-09-create-blog-like-this/24_review_hello_world_blog_local.png){: width="600" height="315" .normal }

---

### **Step 6: Push 'Hello World!' post to GitHub repository for global access.**

Before pushing a post to the repository, use the following command `bash ./tools/test.sh` to test your post.

![Desktop View](/assets/img/2024-09-create-blog-like-this/25_test_pages_before_post.png){: width="600" height="315" .normal }

A successful test command will look like this:

![Desktop View](/assets/img/2024-09-create-blog-like-this/26_test_pages_success.png){: width="600" height="315" .normal }

If the test command has any errors, read the error information and correct it.<br>
To push the post to the GitHub repository, use the following commands:<br>
+ `git add *`
+ `git -n -m "<write some notes>"`
  + For example: `git -n -m "post hello world"` or `git -n -m "posted Aug2024"`
+ `git push`

After a successful push, you can open your browser to see the result.

![Desktop View](/assets/img/2024-09-create-blog-like-this/27_check_github_action.png){: width="600" height="315" .normal }
![Desktop View](/assets/img/2024-09-create-blog-like-this/28_review_page_update_in_web.png){: width="600" height="315" .normal }
![Desktop View](/assets/img/2024-09-create-blog-like-this/29_review_hello_world_post.png){: width="600" height="315" .normal }

---

### **Appendix: How to delete installed Docker environment.**

Click on the bottom left corner of VSCode `Dev Container:...` to `Close Remote Connection`.

![Desktop View](/assets/img/2024-09-create-blog-like-this/30_close_remote_dev_vscode.png){: width="600" height="315" .normal }
![Desktop View](/assets/img/2024-09-create-blog-like-this/31_close_remote_dev_vscode.png){: width="600" height="315" .normal }

If you want to go back to the remote repository to edit files or write posts, click as shown below:

![Desktop View](/assets/img/2024-09-create-blog-like-this/32_remote_dev_vscode_again.png){: width="600" height="315" .normal }

And if you want to delete the local repository you cloned, the docker environment you installed;<br>
Open Docker Desktop and delete _Containers_, _Images_, _Volumes_, _Builds_ one by one as shown below:

![Desktop View](/assets/img/2024-09-create-blog-like-this/33_delete_container.png){: width="600" height="315" .normal }
![Desktop View](/assets/img/2024-09-create-blog-like-this/34_delete_image.png){: width="600" height="315" .normal }
![Desktop View](/assets/img/2024-09-create-blog-like-this/35_delete_volumes.png){: width="600" height="315" .normal }
![Desktop View](/assets/img/2024-09-create-blog-like-this/36_delete_builds.png){: width="600" height="315" .normal }

The above deletion actions only delete the source code and environment on your local machine. You can start again from [Step 2: Clone and setup docker environment](#step-2-clone-and-setup-docker-environment) to reinstall the local environment. If you want to delete your blog that is hosted on the global network, please delete GitHub Pages according to [this article](https://docs.github.com/en/pages/getting-started-with-github-pages/deleting-a-github-pages-site).
