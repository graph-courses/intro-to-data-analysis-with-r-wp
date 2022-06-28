# Copy staging repo to student repo ----
## GRAPH Courses team
## 2022-06-27

#' Copy HTML files from staging repo then push to GitLab. GitLab is mirrored on GitHub. 
#' GitHub deploys HTML files with GitHub pages
#' These deployed files are then embedded on our WordPress page.
#' The script is still a bit of a mess, (as at 2022-06-27) as I am still going down some rabbitholes to try to minimize repo size

## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Load packages and functions ----
## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
if (!require(pacman)) install.packages("pacman")
pacman::p_load(here, fs, cli, git2r, icesTAF, tidyverse)

blue_print <- function(x) cat(cli::bg_blue(cli::col_white(cli::style_bold(x))))
 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##  Force pull ----
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
system('git pull origin main')

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##  Establish paths  ----
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
from <- gsub("-wp", "-staging", here()) # ASSUMES THAT THE STAGING REPO IS IN THE SAME PARENT FOLDER AS WP REPO. IF NOT, SUPPLY PATH HERE. 
to   <- here()

## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Copy  ----
## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# List dirs to be copied
top_level_dirs_to_copy <- dir_ls(from, regexp = "ch\\d\\d_|global")
file.copy(from = top_level_dirs_to_copy,
          to = to,
          recursive = TRUE)

## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Re-render if necessary  ----
## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Filter files for rendering
rmds_to_render <- 
  fs::dir_ls(to, 
             regexp = "ch\\d\\d_ls\\d\\d_(.*?)",
             recurse = T) %>%
  as_tibble() %>% 
  filter(str_ends(value, "Rmd")) %>% 
  filter(str_detect(value, "/lessons/")) %>% 
  filter(!str_detect(str_to_lower(value), "ch99|ls99|/old/|ch05")) %>% 
  filter(!str_detect(str_to_lower(value), "-copy|-paste")) %>% 
  filter(!str_detect(str_to_lower(value), "/bookdown/")) %>% 
  dplyr::pull(1)

# Errors knitting 6, 7, 11, 13

# batched re-rendering in case of errors
for (rmd in rmds_to_render[14:length(rmds_to_render)]) {
  blue_print(paste0("Rendering: \n", rmd, 
                    "\n(", which(rmd == rmds_to_render), " of ", length(rmds_to_render), ")"
  ))
  rmarkdown::render(rmd)
}

# Now delete non HTML files (there is smarter way to do this [we should be able to copy JUST the html files], but I leave like this for now)
all_repo_files <- dir_ls(to, recurse = T, all = T)

files_to_delete <- 
  all_repo_files %>% 
  as_tibble() %>% 
  filter(!str_detect(value, "\\.html|\\.Rproj|\\.git|\\.gitignore|copy_and_push_to_wp" )) %>% 
  pull(1)

file.remove(files_to_delete)

# Finally, delete empty folders
icesTAF::rmdir(to, recursive = T)

## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Pull then push -wp repo, and squash all but most recent commit  ----
## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# system("git checkout --orphan newBranch")
# system("git add -A")  # Add all files and commit them
# # system(paste0('git commit -m "', Sys.time(), '"'))
# git2r::commit(here(), message = paste0(Sys.time()))
# system("git branch -D main")  # Deletes the master branch
# system("git branch -m main")  # Rename the current branch to master
# system("git push -f origin main")  # Force push master branch to github
# system("git gc --aggressive --prune=all")     # remove the old files

system("git add -A")  # Add all files and commit them
git2r::commit(here(), message = paste0(Sys.time()))
system("git push -f origin main")  # Force push master branch to github
# repo <- here()
# fs::file_delete(here(".git"))
# system('git init -b main')
# system('git add .')
# git2r::commit(repo, message = paste0(Sys.time()))


# system('git fetch origin')
# system('git checkout main')
# system('git reset --hard origin/main')
# system('git pull origin main --force')

# system('git remote add origin https://renkulab.io/gitlab/the-graph-courses/intro-to-data-analysis-with-r-wp')
# system('git push -u --force --set-upstream origin main')



# 
# 
# 
# 
# system('git push --set-upstream origin master')
# system('git push --set-upstream origin master')
# 
# ## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# repo <- here()
# 
# fs::file_delete(here(".git"))
# init(repo, branch = 'main')
# add(repo, path = all_repo_files)
# commit(repo, message = as.character(Sys.time()))
# remote_add(repo, 'origin','https://renkulab.io/gitlab/the-graph-courses/intro-to-data-analysis-with-r-wp')
# push(repo, "origin", "refs/heads/main", set_upstream = TRUE, 
#      credentials = cred_user_pass(Sys.getenv('GITLAB_USERNAME'), 
#                                   Sys.getenv('GITLAB_PASSWORD')))
