#! /bin/tcsh -f

setenv SUBJECTS_DIR /autofs/space/erebus_001/users/data/preprocess/FS/MGH_HCP

set dtroot = /space/erebus/1/users/data/preprocess/FS/MGH_HCP

set subjlist = (BANDA001 \
		BANDA002 \
		BANDA003 )

#`cd $dtroot; echo ID????.long.ID???.b`

set pathlist = ( lh.cst rh.cst \
                 lh.ilf rh.ilf \
                 lh.unc rh.unc \
                 fmajor fminor \
                 lh.atr rh.atr \
                 lh.ccg rh.ccg \
                 lh.cab rh.cab \
                 lh.slfp rh.slfp \
                 lh.slft rh.slft )

set trgsubj = fsaverage_clone

if ($?trgsubj) then
  mkdir -p $dtroot/$trgsubj/dlabel/anatorig
endif

set fslut = $FREESURFER_HOME/FreeSurferColorLUT.txt

set hname = `hostname -s`

if ($#argv > 0) then
  set subjlist = $argv[1]
endif

set tmpdir = /tmp/endpt,surf.$$
mkdir -p $tmpdir

foreach subj ($subjlist)
  if ($hname == launchpad) then         # Parallelize by subject
    pbsubmit -e jhw30 -q p30 -c "$0 $subj"
  else
    foreach pathname ($pathlist)
      foreach pt (1 2)
        if ( $pathname =~ lh.* || ( $pathname =~ fm??or && $pt == 1 ) ) then
          set hemi = lh
        else
          set hemi = rh
        endif

        if ($pathname =~ fm??or) then
          set labelname = $hemi.$pathname
        else
          set labelname = $pathname
        endif

        set invol = \
          $dtroot/$subj/dpath/${pathname}_*_avg33_mni_bbr/endpt$pt.pd.nii.gz
        set pmax = `fslstats $invol -r | awk '{print $2}'`
        set thresh = `echo "$pmax * .1" | bc -l`

        set cmd = mri_mask
        set cmd = ($cmd -T $thresh)
        set cmd = ($cmd $invol)
        set cmd = ($cmd $invol)
        set cmd = ($cmd $tmpdir/$pathname.endpt$pt.nii.gz)
        echo $cmd
        $cmd

        set cmd = mri_vol2surf
        set cmd = ($cmd --mov $tmpdir/$pathname.endpt$pt.nii.gz)
        set cmd = ($cmd --reg $dtroot/$subj/dmri/xfms/anatorig2diff.bbr.dat)
        set cmd = ($cmd --hemi $hemi)
	set cmd = ($cmd --projfrac-avg min max del --surf-fwhm 2)
        #set cmd = ($cmd --projdist-avg -4 4 1 --surf-fwhm 2)
# Use this instead, to get better individual labels (based on MoBa data):
#       set cmd = ($cmd --projdist-max -6 6 1 --fwhm 6 --surf-fwhm 6)
        if ($?trgsubj) then
          set cmd = ($cmd --trgsubject $trgsubj)
          set cmd = ($cmd --o \
            $dtroot/$trgsubj/dlabel/anatorig/$labelname.endpt$pt.$subj.mgz)
        else
          set cmd = ($cmd --o \
            $dtroot/$subj/dlabel/anatorig/$labelname.endpt$pt.mgz)
        endif
        echo $cmd
        $cmd
      end
    end
  endif
end


