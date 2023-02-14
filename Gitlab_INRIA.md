git branch -a

* DEV_2023_Octaveb
  master
  remotes/origin/DEV_2023_Octave
  remotes/origin/HEAD -> origin/master
  remotes/origin/dev_2022
  remotes/origin/feat/python_tools_jupyter
  remotes/origin/master
  remotes/origin/postprocessing_python_tools_2022
  remotes/origin/python_tools
  remotes/origin/release
  remotes/origin/release-v1.3
  
git status
 
On branch DEV_2023_Octaveb
Your branch is up to date with 'origin/DEV_2023_Octave'.

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        modified:   Aforc_CFSR/interp_CFSR.m
        modified:   Aforc_CFSR/make_CFSR.m
        modified:   Aforc_CFSR/process_coast_CFSR.m

no changes added to commit (use "git add" and/or "git commit -a")

git commit -am "Improve Octave compatibility"
 
[DEV_2023_Octaveb 165f6121] Improve Octave compatibility
 3 files changed, 31 insertions(+), 20 deletions(-) 

git status

gives

On branch DEV_2023_Octaveb
Your branch is ahead of 'origin/DEV_2023_Octave' by 1 commit.
  (use "git push" to publish your local commits)

nothing to commit, working tree clean

git push origin DEV_2023_Octaveb:DEV_2023_Octave

gives

Username for 'https://gitlab.inria.fr': andres
Password for 'https://andres@gitlab.inria.fr':
Enumerating objects: 11, done.
Counting objects: 100% (11/11), done.
Delta compression using up to 12 threads
Compressing objects: 100% (6/6), done.
Writing objects: 100% (6/6), 815 bytes | 815.00 KiB/s, done.
Total 6 (delta 5), reused 0 (delta 0)
remote:
remote: To create a merge request for DEV_2023_Octave, visit:
remote:   https://gitlab.inria.fr/croco-ocean/croco_tools/-/merge_requests/new?merge_request%5Bsource_branch%5D=DEV_2023_Octave
remote:
To https://gitlab.inria.fr/croco-ocean/croco_tools.git
   8d77fb52..165f6121  DEV_2023_Octaveb -> DEV_2023_Octave
