#!/usr/bin/perl

#must be run as root

$first = 1;

print "{\n";
print "\t\"data\":[\n\n";

for (`mount | grep "/dev/disk*" | sed s/"on"/","/g | sed s/"(hfs, local, journaled)"/""/g`)
#for (`ls -l /dev/disk* | cut -d"/" -f3 | cut -c1-5 | sort -n | uniq`)
#for (`ls -l /dev/disk/by-id/ | cut -d"/" -f3 | sort -n | uniq -w 3`)
{
#DISK LOOP
$smart_avail=0;
$smart_enabled=0;
$smart_enable_tried=0;
$raid_enable=0;


#next when total 0 at output
        if ($_ eq "total 0\n")
                {
                        next;
                }

    print "\t,\n" if not $first;
    $first = 0;
	
	
@info = split(',', $_);	
$disk ="$info[0]";
$volume ="$info[1]";
chomp($disk);
chomp($volume);

# check if RAID SET
foreach(`diskutil info $disk | grep 'RAID Set UUID:' | cut -d":" -f2`)
{

$raid_UUID=$_;

		# if raid enable
		if ($raid_UUID ne ""){
                $raid_enable=1;
				@raid_disks =(`diskutil listraid $raid_UUID | grep -w '^[0-9]' | awk '{print $2}'`);
				next;
				}
				}





#SMART STATUS LOOP
foreach(`/usr/local/sbin/smartctl -i $disk | grep SMART`)
{

$line=$_;

        # if SMART available -> continue
        if ($line = /Available/){
                $smart_avail=1;
                next;
                        }

        #if SMART is disabled then try to enable it (also offline tests etc)
        if ($line = /Disabled/ & $smart_enable_tried == 0){

                foreach(`/usr/local/sbin/smartctl -i $disk -s on -o on -S on | grep SMART`) {

                        if (/SMART Enabled/){
                                $smart_enabled=1;
                                next;
                        }
                }
        $smart_enable_tried=1;
        }

        if ($line = /Enabled/){
        $smart_enabled=1;
        }
		
}
if ($raid_enable == 1) {
    print "\t{\n";
    print "\t\t\"{#DISKNAME}\":\"$raid_disks[0]\",\n";
	print "\t\t\"{#VOLUMENAME}\":\"$volume\",\n";
    print "\t\t\"{#SMART_ENABLED}\":\"$smart_enabled\"\n";
	print "\t\t\"{#RAID_ENABLED}\":\"$raid_enable\"\n";
    print "\t}\n";
}else {
    print "\t{\n";
    print "\t\t\"{#DISKNAME}\":\"$disk\",\n";
	print "\t\t\"{#VOLUMENAME}\":\"$volume\",\n";
    print "\t\t\"{#SMART_ENABLED}\":\"$smart_enabled\"\n";
	#print "\t\t\"{#RAID_ENABLED}\":\"$raid_enable\"\n";
    print "\t}\n";
}
}

print "\n\t]\n";
print "}\n";