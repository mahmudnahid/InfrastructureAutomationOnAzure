# Python Environment Setup
To run the code on a local or remote machine, you can follow the recommendation below.
We use `pip` and `venv`, which are the default Python environment management system and are effective for that purpose.
### Prerequisite
* The code was tested using `Python` 3.10.9, and the environment was set up using `pip` and `venv` (rather than `conda`). I use `vscode` as the IDE.
* Make sure you have a compatible version of Python (3.7.x-3.11.x) and the necessary tools `pip` and `git` installed. You can check if they are installed and see their versions by running `python --version`, `pip --version` (or `pip3 --version`), and `git --version` in the command line. If any of these are missing, please install them according to the official guides: [python](https://www.python.org/downloads/), [pip](https://pip.pypa.io/en/stable/installation/) and [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git).
### Setup Steps
1. The goal of the setup process is to create a virtual environment for the project. The required packages as defined in the `requirements_ecom.txt` files will be installed in the environment. There are two ways to accomplish this, so you can choose the method that works best for you:
    1. **Semi-automatically using the `setup.py` script**: From the root folder, run `python ./env_setup/setup.py`. This should complete all required steps for you. If you get no error, the setup should be completed, and you could verify it by testing it as described below. This script was tested on Windows 11 and Ubuntu 22.04, but not Mac (although it is likely to work). It may also be helpful to spend a few minutes reviewing `setup.py` to see how it implements the manual steps below.
    2. **Manually** - following the steps below in the command line:
        1. Create a subfolder named `venv` within the root folder, i.e. by `mkdir venv`
        2. `cd` into `venv` and initialize an environment by running:
            * `python -m venv ecom`
        3. `cd` out back to the repository root folder, and activate the `ecom` virtual environment by running:
            * Linux or Mac: `source ./venv/ecom/bin/activate` 
            * Windows CMD: `.\venv\ecom\Scripts\activate.bat`
            * Windows Powershell: `.\venv\ecom\Scripts\Activate.ps1`
         4. Install the packages: `pip install -r requirements_ecom.txt`
         5. Deactivate the environment by: `deactivate`

### Setting Up `vscode` to work with Virtual Environments
* `vscode` needs to be restarted after setting up the virtual environments for the first time. Otherwise, the environments will not be visible in `vscode`.
* To run Python code in `vscode`, you first need to install the `Python` extension by Microsoft (done via the Extensions menu on the left sidebar). 
* Note that if you see wiggly orange lines below the package names in the import statement, change the interpreter to that of the virtual environment by typing in the command-palette `Python: Select Interpreter` ([stackoverflow](https://stackoverflow.com/a/72721797/10006823)).


### Notes
* For a good context about Python's `venv` module, see its (well-written) [official doc](https://docs.python.org/3/tutorial/venv.html))
* Your Python executable might be `python3` rather than `python` (e.g. as in Ubuntu 22.04 due to a [historical root-casue](https://itsfoss.com/python-not-found-ubuntu/#:~:text=It's%20because%20the%20Python%20language,available%20as%20python%20package%2Fexecutable.)). In that case simply replace `python` with `python3` above, and in the manual method below, if you decide to run it.
