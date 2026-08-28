
# npwd_qbx_garages
Garage Application for NPWD Phone

## Dependencies
- [qbx_core](https://github.com/Qbox-project/qbx_core)
- [qbx_garages](https://github.com/Qbox-project/qbx_garages)
- [ox_lib](https://github.com/overextended/ox_lib)
- [oxmysql](https://github.com/overextended/oxmysql)
- [NPWD](https://github.com/project-error/npwd)

## Install

#### Please note that this project is still under development and is not yet fully prepared for use. Experienced individuals may proceed with building the source code, while others are advised to await further updates.

How to build the source code:

    git clone https://github.com/Qbox-project/npwd_qbx_garages.git
    cd npwd_qbx_garages/src
    pnpm i
    pnpm build

Once it's build, follow the steps below:
1. Ensure `npwd_qbx_garages` BEFORE `npwd`
2. Add app to NPWD config.json in the `apps` section `"apps": ["npwd_qbx_garages"]`

#### Do not change the resource name. You must download the source code, alter `fetchNui.ts`, and build the project to change it.

## Screenshots
![dark](https://github.com/Qbox-project/npwd_qbx_garages/assets/7904473/0c67b147-ae82-47f4-acaf-83cd7c283e46) ![light](https://github.com/Qbox-project/npwd_qbx_garages/assets/7904473/ff44f9b4-7c63-41c0-8201-8b6d7a993446)
