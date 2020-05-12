#/bin/nash

#-----------some variable declaration------------
HELP_MESSAGE="Usage: khinsider.sh [OPTIONS] [url]

Simple script to download a full album from download.khinsider.com.

Options:

-d		specify output directory. By default, into tmp/khinsider
-h		print this message
-y		doesn't ask for folder creation

"

#-----------Options management-------------------
while getopts "d:h:y" option
do
	case $option in
		d)
			output_dir=$OPTARG
			;;
		h)
			echo $HELP_MESSAGE
			exit
			;;
		y)
			allow_creation=1
			;;
		\?)
			echo "$OPTARG: invalid option"
			echo "khinsider.sh -h for help"
			exit
			;;
	esac
done

source=`pwd`
tmp_path="/tmp/khinsider/$$"
shift $((OPTIND-1))
if [ "$#" -ne 1 ]
then
	echo "Illegal number of arguments"
	exit
fi

#verify that the targeted folder is not a file
if [ -f $output_dir ] && [ ! -z $output_dir ]
then
	echo "$target_folder is a file, exiting..."
	exit
fi

#select default folder if needed
if [ ! -v output_dir ]
then
	output_dir="/tmp/khinsider"
fi
if [ ! -v allow_creation ]
then
	allow_creation=0
fi

#verify that the target folder exists
if [ ! -d $output_dir ]
then
	if [ $allow_creation -eq 1 ]
	then
		mkdir -p $output_dir
	else
		read -p "$output_dir doesn't exists, do you want to create it ?(y/n)" create_folder
		if [[ ${create_folder} == "y" ]]
		then
			mkdir -p $output_dir
		else
			echo "Exiting due to non-existant target folder..."
			exit
		fi
	fi
fi

url=$1
mkdir -p $tmp_path
cd $tmp_path

wget $url -O page -q
sed -n '/<table id="songlist">/, /<\/table>/p' page > table
sed  '/<td class="playlistDownloadSong">/!d' table | grep -o 'href="[^"]*"' | grep -o '"[^"]*"' | sed 's/^.\(.*\).$/\1/' > links_table
nb_songs=`cat links_table | wc -l`
echo "${nb_songs} elements to download"
song_number=0

for ligne in `cat links_table`
do
	page_name="page_$song_number"
	sec_url="https://downloads.khinsider.com$ligne"
	wget $sec_url -O $page_name -q
	song_url=`sed '/<audio id="audio"/!d' $page_name |grep -o 'src="[^"]*"' | grep -o '"[^*]*"' | sed 's/^.\(.*\).$/\1/'`
	wget $song_url -q --show-progress -P $output_dir
	echo -en "\r"
	((song_number+=1))
done

rm -rf $tmp_path
