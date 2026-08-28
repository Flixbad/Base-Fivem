# npwd_qbx_mail
Mail Application for NPWD Phone

## Dependencies
- [qbx_core](https://github.com/Qbox-project/qbx_core)
- [ox_lib](https://github.com/overextended/ox_lib)
- [oxmysql](https://github.com/overextended/oxmysql)
- [NPWD](https://github.com/project-error/npwd)

## Install

#### Please note that this project is still under development and is not yet fully prepared for use. Experienced individuals may proceed with building the source code, while others are advised to await further updates.

How to build the source code:

    git clone https://github.com/Qbox-project/npwd_qbx_mail.git
    cd npwd_qbx_mail/src
    pnpm i
    pnpm build

Once it's build, follow the steps below:
1. Ensure `npwd_qbx_mail` BEFORE `npwd`
2. Add app to NPWD config.json in the `apps` section `"apps": ["npwd_qbx_mail"]`

#### Do not change the resource name. You must download the source code, alter `fetchNui.ts`, and build the project to change it.

## Screenshots
![dark_inbox](https://github.com/Qbox-project/npwd_qbx_mail/assets/7904473/88bf707e-528c-4af8-8650-9fb289754a7f) ![dark_message](https://github.com/Qbox-project/npwd_qbx_mail/assets/7904473/0c71cda6-5fd2-4cf6-adf8-4dccf6b560be)
![light_inbox](https://github.com/Qbox-project/npwd_qbx_mail/assets/7904473/d0e9386d-740f-4b9d-af14-3e343d70593a) ![light_message](https://github.com/Qbox-project/npwd_qbx_mail/assets/7904473/88619014-5485-4c26-9677-bfee7f7c857f)

