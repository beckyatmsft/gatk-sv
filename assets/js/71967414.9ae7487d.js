"use strict";(self.webpackChunkGATK_SV=self.webpackChunkGATK_SV||[]).push([[733],{3905:(e,t,n)=>{n.d(t,{Zo:()=>m,kt:()=>h});var r=n(7294);function a(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function o(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);t&&(r=r.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,r)}return n}function i(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?o(Object(n),!0).forEach((function(t){a(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):o(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function l(e,t){if(null==e)return{};var n,r,a=function(e,t){if(null==e)return{};var n,r,a={},o=Object.keys(e);for(r=0;r<o.length;r++)n=o[r],t.indexOf(n)>=0||(a[n]=e[n]);return a}(e,t);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);for(r=0;r<o.length;r++)n=o[r],t.indexOf(n)>=0||Object.prototype.propertyIsEnumerable.call(e,n)&&(a[n]=e[n])}return a}var s=r.createContext({}),p=function(e){var t=r.useContext(s),n=t;return e&&(n="function"==typeof e?e(t):i(i({},t),e)),n},m=function(e){var t=p(e.components);return r.createElement(s.Provider,{value:t},e.children)},c="mdxType",u={inlineCode:"code",wrapper:function(e){var t=e.children;return r.createElement(r.Fragment,{},t)}},d=r.forwardRef((function(e,t){var n=e.components,a=e.mdxType,o=e.originalType,s=e.parentName,m=l(e,["components","mdxType","originalType","parentName"]),c=p(n),d=a,h=c["".concat(s,".").concat(d)]||c[d]||u[d]||o;return n?r.createElement(h,i(i({ref:t},m),{},{components:n})):r.createElement(h,i({ref:t},m))}));function h(e,t){var n=arguments,a=t&&t.mdxType;if("string"==typeof e||a){var o=n.length,i=new Array(o);i[0]=d;var l={};for(var s in t)hasOwnProperty.call(t,s)&&(l[s]=t[s]);l.originalType=e,l[c]="string"==typeof e?e:a,i[1]=l;for(var p=2;p<o;p++)i[p]=n[p];return r.createElement.apply(null,i)}return r.createElement.apply(null,n)}d.displayName="MDXCreateElement"},1043:(e,t,n)=>{n.r(t),n.d(t,{assets:()=>s,contentTitle:()=>i,default:()=>u,frontMatter:()=>o,metadata:()=>l,toc:()=>p});var r=n(7462),a=(n(7294),n(3905));const o={title:"Runtime Environments",description:"Describes the supported runtime environments.",sidebar_position:7,slug:"./runtime-env"},i=void 0,l={unversionedId:"gs/runtime_env",id:"gs/runtime_env",title:"Runtime Environments",description:"Describes the supported runtime environments.",source:"@site/docs/gs/runtime_env.md",sourceDirName:"gs",slug:"/gs/runtime-env",permalink:"/gatk-sv/docs/gs/runtime-env",draft:!1,editUrl:"https://github.com/broadinstitute/gatk-sv/tree/master/website/docs/gs/runtime_env.md",tags:[],version:"current",sidebarPosition:7,frontMatter:{title:"Runtime Environments",description:"Describes the supported runtime environments.",sidebar_position:7,slug:"./runtime-env"},sidebar:"tutorialSidebar",previous:{title:"Input Data",permalink:"/gatk-sv/docs/gs/inputs"},next:{title:"Execution modes",permalink:"/gatk-sv/docs/category/execution-modes"}},s={},p=[{value:"Alternative backends",id:"alternative-backends",level:2}],m={toc:p},c="wrapper";function u(e){let{components:t,...n}=e;return(0,a.kt)(c,(0,r.Z)({},m,n,{components:t,mdxType:"MDXLayout"}),(0,a.kt)("p",null,"The GATK-SV pipeline consists of ",(0,a.kt)("em",{parentName:"p"},"workflows")," and ",(0,a.kt)("em",{parentName:"p"},"reference data")," that\norchestrates the analysis flow of input data. Hence, a successful\nexecution requires running the ",(0,a.kt)("em",{parentName:"p"},"workflows")," on ",(0,a.kt)("em",{parentName:"p"},"reference")," and input data."),(0,a.kt)("admonition",{title:"Currently supported backends: GCP",type:"info"},(0,a.kt)("p",{parentName:"admonition"},"GATK-SV has been tested only on the Google Cloud Platform (GCP);\ntherefore, we are unable to provide specific guidance or support\nfor other execution platforms including HPC clusters and AWS.")),(0,a.kt)("h2",{id:"alternative-backends"},"Alternative backends"),(0,a.kt)("p",null,"Contributions from the community to improve portability between backends\nwill be considered on a case-by-case-basis. We ask contributors to\nplease adhere to the following guidelines when submitting issues and pull requests:"),(0,a.kt)("ol",null,(0,a.kt)("li",{parentName:"ol"},"Code changes must be functionally equivalent on GCP backends, i.e. not result in changed output"),(0,a.kt)("li",{parentName:"ol"},"Increases to cost and runtime on GCP backends should be minimal"),(0,a.kt)("li",{parentName:"ol"},"Avoid adding new inputs and tasks to workflows. Simpler changes\nare more likely to be approved, e.g. small in-line changes to scripts or WDL task command sections"),(0,a.kt)("li",{parentName:"ol"},"Avoid introducing new code paths, e.g. conditional statements"),(0,a.kt)("li",{parentName:"ol"},"Additional backend-specific scripts, workflows, tests, and Dockerfiles will not be approved"),(0,a.kt)("li",{parentName:"ol"},"Changes to Dockerfiles may require extensive testing before approval")),(0,a.kt)("p",null,"We still encourage members of the community to adapt GATK-SV for non-GCP backends\nand share code on forked repositories. Here are a some considerations:"),(0,a.kt)("ul",null,(0,a.kt)("li",{parentName:"ul"},(0,a.kt)("p",{parentName:"li"},"Refer to Cromwell's ",(0,a.kt)("a",{parentName:"p",href:"https://cromwell.readthedocs.io/en/stable/backends/Backends/"},"documentation"),"\nfor configuration instructions.")),(0,a.kt)("li",{parentName:"ul"},(0,a.kt)("p",{parentName:"li"},"The handling and ordering of ",(0,a.kt)("inlineCode",{parentName:"p"},"glob")," commands may differ between platforms.")),(0,a.kt)("li",{parentName:"ul"},(0,a.kt)("p",{parentName:"li"},"Shell commands that are potentially destructive to input files\n(e.g. ",(0,a.kt)("inlineCode",{parentName:"p"},"rm"),", ",(0,a.kt)("inlineCode",{parentName:"p"},"mv"),", ",(0,a.kt)("inlineCode",{parentName:"p"},"tabix"),") can cause unexpected behavior on shared filesystems.\nEnabling ",(0,a.kt)("a",{parentName:"p",href:"https://cromwell.readthedocs.io/en/stable/Configuring/#local-filesystem-options"},"copy localization"),"\nmay help to more closely replicate the behavior on GCP.")),(0,a.kt)("li",{parentName:"ul"},(0,a.kt)("p",{parentName:"li"},"For clusters that do not support Docker, Singularity is an alternative.\nSee ",(0,a.kt)("a",{parentName:"p",href:"https://cromwell.readthedocs.io/en/stable/tutorials/Containers/#singularity"},"Cromwell documentation on Singularity"),".")),(0,a.kt)("li",{parentName:"ul"},(0,a.kt)("p",{parentName:"li"},"The GATK-SV pipeline takes advantage of the massive parallelization possible in the cloud.\nLocal backends may not have the resources to execute all of the workflows.\nWorkflows that use fewer resources or that are less parallelized may be more successful.\nFor instance, some users have been able to run ",(0,a.kt)("a",{parentName:"p",href:"#gather-sample-evidence"},"GatherSampleEvidence")," on a SLURM cluster."))),(0,a.kt)("h1",{id:"cromwell"},"Cromwell"),(0,a.kt)("p",null,(0,a.kt)("a",{parentName:"p",href:"https://github.com/broadinstitute/cromwell"},"Cromwell")," is a workflow management system\nthat takes a workflow (e.g., a workflow written in ",(0,a.kt)("a",{parentName:"p",href:"https://openwdl.org"},"Workflow Description Language (WDL)"),"),\nits dependencies and input data, and runs it on a given platform\n(e.g., ",(0,a.kt)("a",{parentName:"p",href:"https://cromwell.readthedocs.io/en/stable/backends/Google/"},"GCP"),").\nIn order to run a workflow on Cromwell, you need a running instance of\nCromwell that is available in two forms: ",(0,a.kt)("a",{parentName:"p",href:"https://cromwell.readthedocs.io/en/stable/Modes/"},"Server and stand-alone mode"),"."),(0,a.kt)("p",null,"In general, you may use a managed Cromwell server maintained by your\ninstitute or host a self-managed server, or run Cromwell as a standalone Java application.\nThe former is ideal for large scale execution in a managed environment,\nand the latter is useful for small scale and isolated WDL development."),(0,a.kt)("admonition",{type:"info"},(0,a.kt)("p",{parentName:"admonition"},"Due to its dependency on cloud-hosted resources and large-scale execution needs,\nwe currently do not support running the entire GATK-SV pipeline using\nCromwell as a ",(0,a.kt)("a",{parentName:"p",href:"https://cromwell.readthedocs.io/en/stable/Modes/#run"},"stand-alone Java application")," ")),(0,a.kt)("h1",{id:"cromwell-server"},"Cromwell Server"),(0,a.kt)("p",null,"There are two option to communicate with a running Cromwell server:\n",(0,a.kt)("a",{parentName:"p",href:"https://cromwell.readthedocs.io/en/stable/tutorials/ServerMode/"},"REST API"),", and\n",(0,a.kt)("a",{parentName:"p",href:"https://github.com/broadinstitute/cromshell"},"Cromshell")," which is a command line tool\nto interface with a Cromwell server. We recommend using Cromshell due to its simplicity\nof use. This documentation is explained using Cromshell, but the same steps can be\ntaken using the REST API."),(0,a.kt)("ul",null,(0,a.kt)("li",{parentName:"ul"},(0,a.kt)("p",{parentName:"li"},(0,a.kt)("strong",{parentName:"p"},"Setup Cromwell"),": You may follow ",(0,a.kt)("a",{parentName:"p",href:"https://cromwell.readthedocs.io/en/stable/Modes/"},"this")," documentation\non setting up a Cromwell server.")),(0,a.kt)("li",{parentName:"ul"},(0,a.kt)("p",{parentName:"li"},(0,a.kt)("strong",{parentName:"p"},"Setup Cromshell"),": You may follow ",(0,a.kt)("a",{parentName:"p",href:"https://github.com/broadinstitute/cromshell"},"this")," documentation\non installing and configuring Cromshell to communicate with the Cromwell server."))))}u.isMDXComponent=!0}}]);