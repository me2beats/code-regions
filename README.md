# code-regions

```gdscript
#region MyFirstRegion

[your code]
[your code]
...

#region_end
```

Then you can right click on the region start line (`#region MyFirstRegion`) and select `Hide Region` to hide the code block

Current Limitations:
1. Indentation level should be the same (for region start and end).
2. Indentation level should be 2 or more (3,4 ..), not 1. This means for example classes can't be collapsed
3. When changing the region color and other parameters in the script (in the user area), the editor should be reloaded (at least the plugin and scripts)

https://user-images.githubusercontent.com/16458555/146563822-1ab68338-1085-4d55-8926-61cb3d32d8e2.mp4

