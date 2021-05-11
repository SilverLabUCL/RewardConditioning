# RewardConditioning
Protocols for reward conditioning tasks

1. Water valve calibration
2. Licking

3. Conditioning (Reward after delay, Stim throughout)
4. Trace conditioning (Reward after delay, stim only in sample)

5. Operant task (Lick for reward after delay, stim throughout)
6. Operant (trace-delay) task (Lick for reward after delay, stim only in sample)

7. No anticipatory licks (No lick in delay, reward after delay)
8. Timing operant task (No lick in delay, lick for reward after delay)


For sound-cued conditioning, only protocols 1,2,4,6,7,8 are applicable as there is no sound for delay period.

#### Which branch and task folder?
- Main branch 
- For Behaviour rig, use folder: [RewardConditioning_Sound](https://github.com/SilverLabUCL/RewardConditioning/tree/main/RewardConditioning_Sound)
- For Rig2, use folder: [RewardConditioning_Sound_rig2](https://github.com/SilverLabUCL/RewardConditioning/tree/main/RewardConditioning_Sound_rig2)

This allows working in Triggered mode (`IsRig2=1/True`) or Normal mode (`IsRig2=0/false`). Waiting time for trial trigger can be updated on any trial using the GUI. Furthermore, post-reward, one can go to a post-baseline period (`WaitForStopLick=0/false`), or wait for the animal to stop licking for requisite period (`WaitForStopLick=1\true`). The latter is useful during training but for imaging, the former is recommended to have fully aligned imaging and behaviour trials.

See [Wiki](https://github.com/SilverLabUCL/RewardConditioning/wiki/Training-on-Reward-Based-Conditioning) for recommended training procedures.
