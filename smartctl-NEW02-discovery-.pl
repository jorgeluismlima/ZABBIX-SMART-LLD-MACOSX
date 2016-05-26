#!/usr/bin/perl

$first = 1;

print "{\n";
print "\t\"data\":[\n\n";

for (`diskutil list | grep 2:` ){


$smart_avail=0;
$smart_enabled=0;
$smart_enable_tried=0;

$raid_enable=0;
@info = split(' ', $_);
$type ="$info[1]";
$disk ="$info[-1]";
chomp($disk);
chomp($type);

    print "\t,\n" if not $first;
    $first = 0;

#SMART STATUS LOOP
foreach(`/usr/local/sbin/smartctl -i /dev/$disk | grep SMART`)
{

$line=$_;

        # if SMART available -> continue
        if ($line = /Available/){
                $smart_avail=1;
                next;
                        }

        #if SMART is disabled then try to enable it (also offline tests etc)
        if ($line = /Disabled/ & $smart_enable_tried == 0){

                foreach(`/usr/local/sbin/smartctl -i /dev/$disk -s on -o on -S on | grep SMART`) {

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

    print "\t{\n";
    print "\t\t\"{#DISKNAME}\":\"$disk\",\n";
	print "\t\t\"{#TYPE}\":\"$type\",\n";
    print "\t\t\"{#SMART_ENABLED}\":\"$smart_enabled\"\n";
    print "\t}\n";

}

print "\n\t]\n";
print "}\n";
