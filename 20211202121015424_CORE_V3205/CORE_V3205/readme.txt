固件功能说明
1.3基线(目前固定发布以下5种类型的固件）：
Luat_V30XX_RDA8910 ：支持LCD,字库，图片，扫码，生成二维码，摄像头，WIFI Scan，SD卡，littleVGL，VOLTE
Luat_V30XX_RDA8910_BT_FLOAT：支持LCD,字库，图片，扫码，生成二维码，摄像头，WIFI Scan，蓝牙，SD卡，littleVGL，FLOAT
Luat_V30XX_RDA8910_RBTTSQRLLSDFT：支持LCD,字库，图片，扫码，生成二维码，摄像头，TTS,WIFI Scan，蓝牙，SD卡，littleVGL，FLOAT
Luat_V30XX_RDA8910_TTS_NOVOLTE_FLOAT:支持LCD,字库，图片，扫码，生成二维码，摄像头，WIFI Scan,SD卡，littleVGL
Luat_V30XX_RDA8910_TTS_NOLVGL_FLOAT:支持LCD,字库，图片，TTS,WIFI Scan,SD卡,VOLTE
LuatOS-HMI_V32XX_RDA8910
另外：针对客户不同功能使用场景，提供免费在线定制固件服务。满足客户功能定制化需求，同时也能最大化保留Lua运行和存储空间
定制系统：https://doc.openluat.com/shareArticle/Vf34iUQh9em7c
详细说明参考：https://doc.openluat.com/article/1334/0


1.2基线（目前固定发布以下5种类型固件，不支持定制固件）：
Luat_V00XX_RDA8910:支持LCD,字库，图片，扫码，生成二维码，摄像头,WIFI Scan，SD卡，littleVGL，VOLTE
Luat_V00XX_RDA8910_FLOAT:支持LCD,字库，图片，扫码，生成二维码，摄像头,WIFI Scan，SD卡，littleVGL，VOLTE,FLOAT
Luat_V00XX_RDA8910_TTS:支持LCD,字库，图片,TTS,WIFI Scan,littleVGL，VOLTE
Luat_V00XX_RDA8910_TTS_FLOAT:支持LCD,字库，图片,TTS,WIFI Scan,littleVGL，VOLTE,FLOAT
Luat_V00XX_RDA8910_TTS_NOLVGL:支持LCD,字库，图片,TTS,WIFI Scan,VOLTE
详细说明参考：https://doc.openluat.com/article/1334/0


空间说明：
Luat二次开发使用的Flash空间有两部分：脚本区和文件系统区
脚本区：
通过Luatools烧写的所有文件，都存放在此区域
非TTS版本为720KB，TTS版本为426KB；如果烧录时，超过此限制，Luatools会报错
不同版本的core可能会有差异，以版本每次的更新记录为准
文件系统区：
程序运行过程中实时创建的文件都会存放在此区域，例如下载的一些音源文件  
总空间为1.3MB 
不同版本的core可能会有差异，可通过rtos.get_fs_free_size()查询剩余的文件系统可用空间
下载的差分升级包也存放在文件系统区，为保证差分升级可以用，建议预留900KB给差分升级使用 

Luat二次开发可用的ram空间有1.36MB
可通过collectgarbage("count")查询已经使用的内存空间（返回值单位为KB）,总的1.36MB减去使用的内存，就是当前剩余的Lua运行可用内存



详细说明参考：https://doc.openluat.com/article/1334/0
注：         .pac后缀的是本地烧录固件； .bin后缀的是空中升级文件