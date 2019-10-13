all: testcreatedfd testinterpretdfd testbidirectionalmapping

# Note. Currently we use an unreleased version of vulkan_core.h with enums
# for ASTC 3D. Since this is temporary, the sources still use <angled>
# includes. The -I. causes our local copy to be found while the VULKAN_SDK
# part keeps compilers from warning that the file was not found with
# <angled> include.
testcreatedfd: createdfd.c createdfdtest.c printdfd.c KHR/khr_df.h
	gcc createdfdtest.c createdfd.c printdfd.c -I. $(if VULKAN_SDK,-I${VULKAN_SDK}/include) -o $@ -std=c99 -W -Wall -pedantic -O2 -Wno-strict-aliasing

testinterpretdfd: createdfd.c interpretdfd.c interpretdfdtest.c printdfd.c KHR/khr_df.h
	gcc interpretdfd.c createdfd.c interpretdfdtest.c printdfd.c -o $@ -I. $(if VULKAN_SDK,-I${VULKAN_SDK}/include) -O -W -Wall -std=c99 -pedantic

testbidirectionalmapping: testbidirectionalmapping.c interpretdfd.c createdfd.c KHR/khr_df.h
	gcc testbidirectionalmapping.c interpretdfd.c createdfd.c -o $@ -I. $(if VULKAN_SDK,-I${VULKAN_SDK}/include) -O -W -Wall -std=c99 -pedantic

clean:
	rm -f testcreatedfd testinterpretdfd testbidirectionalmapping

switches: dfd2vk.inl vk2dfd.inl

dfd2vk.inl: vulkan/vulkan_core.h makedfdtovk.pl
	./makedfdtovk.pl $< $@

vk2dfd.inl: vulkan/vulkan_core.h makevkswitch.pl
	./makevkswitch.pl $< $@
