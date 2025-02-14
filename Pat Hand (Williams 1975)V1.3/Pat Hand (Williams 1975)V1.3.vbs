' ******************************************************************
'       VPX - version by Klodo81 2023, Pat Hand version 1.3
'
'                 VISUAL PINBALL X EM Script Based on
'               JPSalas Basic EM script up to 4 players		          
'                       JPSalas Physics 4.3.0	
'
'          Pat Hand / IPD No.1767 / May 07, 1975 / 4 Players   
'
'V1.1 mod table and backglass
'- Mod Backglass Can Play  (download the backglass)
'- Mod Song more realistic with 3 chimes
'- Added typical sounds proposed by Mustang1961
'- Add option no attract mode in script 
'- Reduced gap between the flippers
'
'V1.2 mod table and backglass
'- Mod Backglass with new image from HiREZ00  (download the backglass)
'- Mod Table with new image for DT Mode
'
'V1.3 mod table
'- Mod Rev3 Physics from JPSalas
'- Some others little things
' ******************************************************************

Option Explicit
Randomize

' DOF config
'
' Flippers L/R - 101/102
' Slingshot R - 104
' Bumpers T/B - 105/106
' Targets Round M/R - 201/202
' Triggers - 205/206
' Knocker - 110
' Chimes - 301/302/303
' Drain - 250

' core.vbs constants
Const BallSize = 50 ' 50 is the normal size
Const BallMass = 1  ' 1 is the normal ball mass.

' load extra vbs files
LoadCoreFiles

Sub LoadCoreFiles
    On Error Resume Next
    ExecuteGlobal GetTextFile("core.vbs")
    If Err Then MsgBox "Can't open core.vbs"
    On Error Resume Next
    ExecuteGlobal GetTextFile("controller.vbs")
    If Err Then MsgBox "Can't open controller.vbs"
End Sub

'****************** Options you can change *******************

Const BallsPerGame = 5     ' to play with 3 or 5 balls
Const AttractMode = 1      ' 0 = no attract mode
 
'*************************************************************

' Constants
Const TableName = "PatHand_75VPX"   ' file name to save highscores and other variables
Const cGameName = "pathand1975"   ' B2S name
Const MaxPlayers = 4        ' 1 to 4 can play
Const Special1 = 55000      ' 3 Balls award credit
Const Special2 = 72000      ' 3 Balls award credit
Const Special3 = 94000      ' 3 Balls award credit
Const Special4 = 76000      ' 5 Balls award credit
Const Special5 = 98000      ' 5 Balls award credit

' Global variables
Dim PlayersPlayingGame
Dim CurrentPlayer
Dim Credits
Dim Bonus
Dim BallsRemaining(4)
Dim BonusMultiplier
Dim ExtraBallsAwards(4)
Dim Special1Awarded(4)
Dim Special2Awarded(4)
Dim Special3Awarded(4)
Dim Special4Awarded(4)
Dim Special5Awarded(4)
Dim Score(4)
Dim HighScore
Dim Match
Dim Tilt
Dim TiltSensitivity
Dim Tilted
Dim Add10
Dim Add100
Dim Add1000
Dim Add10000
Dim CardsRun
Dim AltCounter
Dim Alt2Counter
Dim CBonus
Dim x

' Control variables
Dim BallsOnPlayfield

' Boolean variables
Dim bAttractMode
Dim bFreePlay
Dim bGameInPlay
Dim bOnTheFirstBall
Dim bExtraBallWonThisBall
Dim bJustStarted
Dim bBallInPlungerLane
Dim bBallSaverActive

' core.vbs variables

' *********************************************************************
'                Common rutines to all the tables
' *********************************************************************

Sub Table1_Init()
    Dim x

    ' Init som objects, like walls, targets
    VPObjects_Init
    LoadEM

    ' load highscores and credits
    Loadhs
    ScoreReel1.SetValue HSScore(1)
    If B2SOn then
        Controller.B2SSetScorePlayer 1, HSScore(1)
    End If
    UpdateCredits

    ' Free play or Coins
    bFreePlay = False

    ' init all the global variables
    bAttractMode = False
    bOnTheFirstBall = False
    bGameInPlay = False
    bBallInPlungerLane = False
    BallsOnPlayfield = 0
    Tilt = 0
    TiltSensitivity = 6
    Tilted = False
    Match = 0
    bJustStarted = True
    Add10 = 0
    Add100 = 0
    Add1000 = 0
    Add1000 = 0

	' select Card instruction on Apron
	If BallsPerGame = 3 Then
		Flasher3balls.visible = 1
		Flasher5balls.visible = 0
	Else 'BallsPerGame = 5
		Flasher3balls.visible = 0
		Flasher5balls.visible = 1
	End If

	'Test position Match on desktop screen
	'Match = 90  '(00 to 90)
	'Display_Match

    ' setup table in game over mode
    EndOfGame

    'turn on GI lights
    vpmtimer.addtimer 1000, "GiOn '"

    ' Remove desktop items in FS mode
    If Table1.ShowDT then
        For each x in aReels
            x.Visible = 1
        Next
    Else
        For each x in aReels
            x.Visible = 0
        Next
    End If

    ' LUT - Darkness control
    LoadLUT
End Sub

'******
' Keys
'******

Sub Table1_KeyDown(ByVal Keycode)

    If EnteringInitials then
        CollectInitials(keycode)
        Exit Sub
    End If

    If keycode = LeftMagnaSave Then bLutActive = True: Lutbox.text = "level of darkness " & LUTImage + 1
    If keycode = RightMagnaSave Then
        If bLutActive Then NextLUT:End If
    End If

    ' add coins
    If Keycode = AddCreditKey Then
        If(Tilted = False) Then
            AddCredits 1
            PlaySound "fx_coin"
        End If
    End If

    ' plunger
    If keycode = PlungerKey Then
        Plunger.Pullback
        PlaySoundAt "fx_plungerpull", plunger
    End If

    ' tilt keys
    If keycode = LeftTiltKey Then Nudge 90, 5:PlaySound "fx_nudge", 0, 1, -0.1, 0.25:CheckTilt
    If keycode = RightTiltKey Then Nudge 270, 5:PlaySound "fx_nudge", 0, 1, 0.1, 0.25:CheckTilt
    If keycode = CenterTiltKey Then Nudge 0, 6:PlaySound "fx_nudge", 0, 1, 1, 0.25:CheckTilt

    ' keys during game

    If bGameInPlay AND NOT Tilted Then

        If keycode = LeftFlipperKey Then SolLFlipper 1
        If keycode = RightFlipperKey Then SolRFlipper 1

        If keycode = StartGameKey Then
            If((PlayersPlayingGame <MaxPlayers) AND(bOnTheFirstBall = True) ) Then

                If(bFreePlay = True) Then
                    PlayersPlayingGame = PlayersPlayingGame + 1    
                    UpdateBallInPlay
					UpdatePlayers
                Else
                    If(Credits> 0) then
                        PlayersPlayingGame = PlayersPlayingGame + 1
                        Credits = Credits - 1
                        UpdateCredits
                        UpdateBallInPlay
						UpdatePlayers
						Playsound"BallyStartButtonPlayers2-4 plus 10dB"
                    End If
                End If
            End If
        End If
        Else ' If (GameInPlay)

            If keycode = StartGameKey Then
                If(bFreePlay = True) Then
                    If(BallsOnPlayfield = 0) Then
                        ResetScores
                        ResetForNewGame()
                    End If
                Else
                    If(Credits> 0) Then
                        If(BallsOnPlayfield = 0) Then
                            Credits = Credits - 1
                            UpdateCredits
                            ResetScores
                            ResetForNewGame()
							Playsound"BallyStartButtonPlayer1+3dB"
                        End If
                    End If
                End If
            End If
    End If ' If (GameInPlay)
End Sub

Sub Table1_KeyUp(ByVal keycode)

    If EnteringInitials then
        Exit Sub
    End If

    If keycode = LeftMagnaSave Then bLutActive = False: LutBox.text = ""

    If bGameInPlay AND NOT Tilted Then

        If keycode = LeftFlipperKey Then SolLFlipper 0
        If keycode = RightFlipperKey Then SolRFlipper 0
    End If

    If keycode = PlungerKey Then
        Plunger.Fire
        If bBallInPlungerLane Then
            PlaySoundAt "fx_plunger", plunger
        Else
            PlaySoundAt "fx_plunger_empty", plunger
        End If
    End If
End Sub

'******************
' Table stop/pause
'******************

Sub table1_Paused
End Sub

Sub table1_unPaused
End Sub

Sub table1_Exit
    Savehs
	'Controller.Stop
End Sub

'***************************
'   LUT - Darkness control 
'***************************

Dim bLutActive, LUTImage

Sub LoadLUT
    bLutActive = False
    x = LoadValue(cGameName, "LUTImage")
    If(x <> "")Then LUTImage = x Else LUTImage = 0
    UpdateLUT
End Sub

Sub SaveLUT
    SaveValue cGameName, "LUTImage", LUTImage
End Sub

Sub NextLUT:LUTImage = (LUTImage + 1)MOD 15:UpdateLUT:SaveLUT:Lutbox.text = "level of darkness " & LUTImage + 1:End Sub

Sub UpdateLUT
    Select Case LutImage
        Case 0:table1.ColorGradeImage = "LUT0":GiIntensity = 1:ChangeGIIntensity 1
        Case 1:table1.ColorGradeImage = "LUT1":GiIntensity = 1.05:ChangeGIIntensity 1
        Case 2:table1.ColorGradeImage = "LUT2":GiIntensity = 1.1:ChangeGIIntensity 1
        Case 3:table1.ColorGradeImage = "LUT3":GiIntensity = 1.15:ChangeGIIntensity 1
        Case 4:table1.ColorGradeImage = "LUT4":GiIntensity = 1.2:ChangeGIIntensity 1
        Case 5:table1.ColorGradeImage = "LUT5":GiIntensity = 1.25:ChangeGIIntensity 1
        Case 6:table1.ColorGradeImage = "LUT6":GiIntensity = 1.3:ChangeGIIntensity 1
        Case 7:table1.ColorGradeImage = "LUT7":GiIntensity = 1.35:ChangeGIIntensity 1
        Case 8:table1.ColorGradeImage = "LUT8":GiIntensity = 1.4:ChangeGIIntensity 1
        Case 9:table1.ColorGradeImage = "LUT9":GiIntensity = 1.45:ChangeGIIntensity 1
        Case 10:table1.ColorGradeImage = "LUT10":GiIntensity = 1.5:ChangeGIIntensity 1
        Case 11:table1.ColorGradeImage = "LUT11":GiIntensity = 1.55:ChangeGIIntensity 1
        Case 12:table1.ColorGradeImage = "LUT12":GiIntensity = 1.6:ChangeGIIntensity 1
        Case 13:table1.ColorGradeImage = "LUT13":GiIntensity = 1.65:ChangeGIIntensity 1
        Case 14:table1.ColorGradeImage = "LUT14":GiIntensity = 1.7:ChangeGIIntensity 1
    End Select
End Sub

Dim GiIntensity
GiIntensity = 1   'used by the LUT changing to increase the GI lights when the table is darker

Sub ChangeGiIntensity(factor) 'changes the intensity scale
    Dim bulb
    For each bulb in aGiLights
        bulb.IntensityScale = GiIntensity * factor
    Next
End Sub

'**********************************************
'    Flipper adjustments - enable tricks
'             by JLouLouLou
'**********************************************

Dim FlipperPower
Dim FlipperElasticity
Dim SOSTorque, SOSAngle
Dim FullStrokeEOS_Torque, LiveStrokeEOS_Torque
Dim LeftFlipperOn
Dim RightFlipperOn

Dim LLiveCatchTimer
Dim RLiveCatchTimer
Dim LiveCatchSensivity

FlipperPower = 5000
FlipperElasticity = 0.85
FullStrokeEOS_Torque = 0.3 	' EOS Torque when flipper hold up ( EOS Coil is fully charged. Ampere increase due to flipper can't move or when it pushed back when "On". EOS Coil have more power )
LiveStrokeEOS_Torque = 0.2	' EOS Torque when flipper rotate to end ( When flipper move, EOS coil have less Ampere due to flipper can freely move. EOS Coil have less power )

LeftFlipper.EOSTorqueAngle = 10
RightFlipper.EOSTorqueAngle = 10

SOSTorque = 0.1
SOSAngle = 6

LiveCatchSensivity = 10

LLiveCatchTimer = 0
RLiveCatchTimer = 0

LeftFlipper.TimerInterval = 1
LeftFlipper.TimerEnabled = 1

Sub LeftFlipper_Timer 'flipper's tricks timer
'Start Of Stroke Flipper Stroke Routine : Start of Stroke for Tap pass and Tap shoot
    If LeftFlipper.CurrentAngle >= LeftFlipper.StartAngle - SOSAngle Then LeftFlipper.Strength = FlipperPower * SOSTorque else LeftFlipper.Strength = FlipperPower : End If
 
'End Of Stroke Routine : Livecatch and Emply/Full-Charged EOS
	If LeftFlipperOn = 1 Then
		If LeftFlipper.CurrentAngle = LeftFlipper.EndAngle then
			LeftFlipper.EOSTorque = FullStrokeEOS_Torque
			LLiveCatchTimer = LLiveCatchTimer + 1
			If LLiveCatchTimer < LiveCatchSensivity Then
				LeftFlipper.Elasticity = 0
			Else
				LeftFlipper.Elasticity = FlipperElasticity
				LLiveCatchTimer = LiveCatchSensivity
			End If
		End If
	Else
		LeftFlipper.Elasticity = FlipperElasticity
		LeftFlipper.EOSTorque = LiveStrokeEOS_Torque
		LLiveCatchTimer = 0
	End If
	

'Start Of Stroke Flipper Stroke Routine : Start of Stroke for Tap pass and Tap shoot
    If RightFlipper.CurrentAngle <= RightFlipper.StartAngle + SOSAngle Then RightFlipper.Strength = FlipperPower * SOSTorque else RightFlipper.Strength = FlipperPower : End If
 
'End Of Stroke Routine : Livecatch and Emply/Full-Charged EOS
 	If RightFlipperOn = 1 Then
		If RightFlipper.CurrentAngle = RightFlipper.EndAngle Then
			RightFlipper.EOSTorque = FullStrokeEOS_Torque
			RLiveCatchTimer = RLiveCatchTimer + 1
			If RLiveCatchTimer < LiveCatchSensivity Then
				RightFlipper.Elasticity = 0
			Else
				RightFlipper.Elasticity = FlipperElasticity
				RLiveCatchTimer = LiveCatchSensivity
			End If
		End If
	Else
		RightFlipper.Elasticity = FlipperElasticity
		RightFlipper.EOSTorque = LiveStrokeEOS_Torque
		RLiveCatchTimer = 0
	End If

End Sub


'*******************
'  Flipper Subs
'*******************

SolCallback(sLRFlipper) = "SolRFlipper"
SolCallback(sLLFlipper) = "SolLFlipper"

Sub SolLFlipper(Enabled)
    If Enabled Then
        PlaySoundAt SoundFXDOF ("LeftflipperupH-2dB", 101, DOFOn, DOFFlippers), LeftFlipper
        LeftFlipper.RotateToEnd
        LeftFlipper2.RotateToEnd
		LeftFlipperOn = 1
    Else
        PlaySoundAt SoundFXDOF ("LeftflipperdownH", 101, DOFOff, DOFFlippers), LeftFlipper
        LeftFlipper.RotateToStart
        LeftFlipper2.RotateToStart
        LeftFlipperOn = 0
    End If
End Sub

Sub SolRFlipper(Enabled)
    If Enabled Then
        PlaySoundAt SoundFXDOF ("RightflipperupH-2dB", 102, DOFOn, DOFFlippers), RightFlipper
        RightFlipper.RotateToEnd
        RightFlipperOn = 1
    Else
        PlaySoundAt SoundFXDOF ("RightflipperdownH", 102, DOFOff, DOFFlippers), RightFlipper
        RightFlipper.RotateToStart
        RightFlipperOn = 0
    End If
End Sub

Sub LeftFlipper_Collide(parm)
    PlaySound "fx_rubber_flipper", 0, parm / 60, pan(ActiveBall), 0.2, 0, 0, 0, AudioFade(ActiveBall)
End Sub

Sub LeftFlipper2_Collide(parm)
    PlaySound "fx_rubber_flipper", 0, parm / 60, pan(ActiveBall), 0.2, 0, 0, 0, AudioFade(ActiveBall)
End Sub

Sub RightFlipper_Collide(parm)
    PlaySound "fx_rubber_flipper", 0, parm / 60, pan(ActiveBall), 0.2, 0, 0, 0, AudioFade(ActiveBall)
End Sub


'*******************
' GI lights
'*******************

Sub GiOn 'GI lights on
    Dim bulb
    For each bulb in aGiLights
        bulb.State = 1
    Next
End Sub

Sub GiOff 'GI lights off
    Dim bulb
    For each bulb in aGiLights
        bulb.State = 0
    Next
End Sub

'**************
'     TILT
'**************

Sub CheckTilt
    Tilt = Tilt + TiltSensitivity
    TiltDecreaseTimer.Enabled = True
    If Tilt> 15 Then
        Tilted = True
        TiltReel.SetValue 1
        If B2SOn then
            Controller.B2SSetTilt 1
        end if
        DisableTable True
        'BallsRemaining(CurrentPlayer) = 0 'player looses the game
        TiltRecoveryTimer.Enabled = True 'wait for all the balls to drain
    End If
End Sub

Sub TiltDecreaseTimer_Timer
    ' DecreaseTilt
    If Tilt> 0 Then
        Tilt = Tilt - 0.1
    Else
        TiltDecreaseTimer.Enabled = False
    End If
End Sub

Sub DisableTable(Enabled)
    If Enabled Then
        GiOff
        'Disable slings, bumpers etc
        LeftFlipper.RotateToStart
        LeftFlipper2.RotateToStart
        RightFlipper.RotateToStart
        Bumper001.Threshold = 100
        Bumper002.Threshold = 100
        RightSlingshot.Disabled = 1	
        DOF 101, DOFOff
        DOF 102, DOFOff
    Else
        GiOn
        Bumper001.Threshold = 1
        Bumper002.Threshold = 1
        RightSlingshot.Disabled = 0
    End If
End Sub

Sub TiltRecoveryTimer_Timer()
    ' all the balls have drained ..
    If(BallsOnPlayfield = 0) Then
        EndOfBall
        TiltRecoveryTimer.Enabled = False
    End If
' otherwise repeat
End Sub

'***************************************************************
'             Supporting Ball & Sound Functions v4.0
'  includes random pitch in PlaySoundAt and PlaySoundAtBall
'***************************************************************

Dim TableWidth, TableHeight

TableWidth = Table1.width
TableHeight = Table1.height

Function Vol(ball) ' Calculates the Volume of the sound based on the ball speed
    Vol = Csng(BallVel(ball) ^2 / 2000)
End Function

Function Pan(ball) ' Calculates the pan for a ball based on the X position on the table. "table1" is the name of the table
    Dim tmp
    tmp = ball.x * 2 / TableWidth-1
    If tmp > 0 Then
        Pan = Csng(tmp ^10)
    Else
        Pan = Csng(-((- tmp) ^10))
    End If
End Function

Function Pitch(ball) ' Calculates the pitch of the sound based on the ball speed
    Pitch = BallVel(ball) * 20
End Function

Function BallVel(ball) 'Calculates the ball speed
    BallVel = (SQR((ball.VelX ^2) + (ball.VelY ^2)))
End Function

Function AudioFade(ball) 'only on VPX 10.4 and newer
    Dim tmp
    tmp = ball.y * 2 / TableHeight-1
    If tmp > 0 Then
        AudioFade = Csng(tmp ^10)
    Else
        AudioFade = Csng(-((- tmp) ^10))
    End If
End Function

Sub PlaySoundAt(soundname, tableobj) 'play sound at X and Y position of an object, mostly bumpers, flippers and other fast objects
    PlaySound soundname, 0, 1, Pan(tableobj), 0.2, 0, 0, 0, AudioFade(tableobj)
End Sub

Sub PlaySoundAtBall(soundname) ' play a sound at the ball position, like rubbers, targets, metals, plastics
    PlaySound soundname, 0, Vol(ActiveBall), pan(ActiveBall), 0.2, Pitch(ActiveBall) * 10, 0, 0, AudioFade(ActiveBall)
End Sub

Function RndNbr(n) 'returns a random number between 1 and n
    Randomize timer
    RndNbr = Int((n * Rnd) + 1)
End Function

'***********************************
'   JP's VP10 Rolling Sounds v4.0
'   JP's Ball Shadows
'   JP's Ball Speed Control
'   Rothbauer's dropping sounds
'***********************************

Const tnob = 19   'total number of balls
Const lob = 0     'number of locked balls
Const maxvel = 28 'max ball velocity
ReDim rolling(tnob)
InitRolling

Sub InitRolling
    Dim i
    For i = 0 to tnob
        rolling(i) = False
    Next
End Sub

Sub RollingUpdate() 'call this routine from any realtime timer you may have, running at an interval of 10 is good.

    Dim BOT, b, ballpitch, ballvol, speedfactorx, speedfactory
    BOT = GetBalls

    ' stop the sound of deleted balls and hide the shadow
    For b = UBound(BOT) + 1 to tnob
        rolling(b) = False
        StopSound("fx_ballrolling" & b)
        aBallShadow(b).Y = 2100 'under the apron 'may differ from table to table
    Next

    ' exit the sub if no balls on the table
    If UBound(BOT) = lob - 1 Then Exit Sub 'there no extra balls on this table

    ' draw the ball shadow
    For b = lob to UBound(BOT)
        aBallShadow(b).X = BOT(b).X
        aBallShadow(b).Y = BOT(b).Y
        aBallShadow(b).Height = BOT(b).Z - Ballsize / 2 + 1

    'play the rolling sound for each ball
        If BallVel(BOT(b)) > 1 Then
            If BOT(b).z < 30 Then
                ballpitch = Pitch(BOT(b))
                ballvol = Vol(BOT(b))
            Else
                ballpitch = Pitch(BOT(b)) + 50000 'increase the pitch on a ramp
                ballvol = Vol(BOT(b)) * 5
            End If
            rolling(b) = True
            PlaySound("fx_ballrolling" & b), -1, ballvol, Pan(BOT(b)), 0, ballpitch, 1, 0, AudioFade(BOT(b))
        Else
            If rolling(b) = True Then
                StopSound("fx_ballrolling" & b)
                rolling(b) = False
            End If
        End If

        ' rothbauerw's Dropping Sounds
        If BOT(b).VelZ < -1 and BOT(b).z < 55 and BOT(b).z > 27 Then 'height adjust for ball drop sounds
            PlaySound "fx_balldrop", 0, ABS(BOT(b).velz) / 17, Pan(BOT(b)), 0, Pitch(BOT(b)), 1, 0, AudioFade(BOT(b))
        End If

        ' jps ball speed control
        If BOT(b).VelX AND BOT(b).VelY <> 0 Then
            speedfactorx = ABS(maxvel / BOT(b).VelX)
            speedfactory = ABS(maxvel / BOT(b).VelY)
            If speedfactorx < 1 Then
                BOT(b).VelX = BOT(b).VelX * speedfactorx
                BOT(b).VelY = BOT(b).VelY * speedfactorx
            End If
            If speedfactory < 1 Then
                BOT(b).VelX = BOT(b).VelX * speedfactory
                BOT(b).VelY = BOT(b).VelY * speedfactory
            End If
        End If
    Next
End Sub

'**********************
' Ball Collision Sound
'**********************

Sub OnBallBallCollision(ball1, ball2, velocity)
    PlaySound("fx_collide"), 0, Csng(velocity) ^2 / 2000, Pan(ball1), 0, Pitch(ball1), 0, 0, AudioFade(ball1)
End Sub

'***************************************
'     Collection collision sounds
'***************************************

Sub aMetals_Hit(idx):PlaySoundAtBall "fx_MetalHit":End Sub
Sub aMetalWires_Hit(idx):PlaySoundAtBall "fx_MetalWire":End Sub
Sub aRubber_Bands_Hit(idx):PlaySoundAtBall "fx_rubber_band":End Sub
Sub aRubber_Posts_Hit(idx):PlaySoundAtBall "fx_rubber_post":End Sub
Sub aRubber_Pins_Hit(idx):PlaySoundAtBall "fx_rubber_pin":End Sub
Sub aPlastics_Hit(idx):PlaySoundAtBall "fx_PlasticHit":End Sub
Sub aGates_Hit(idx):PlaySoundAtBall "fx_Gate":End Sub
Sub aWoods_Hit(idx):PlaySoundAtBall "fx_Woodhit":End Sub

'added Mustang1961

Sub GR_hit()
	Playsound "fx_gate"
End Sub

'***************************************************************************************************
' Only for VPX 10.2 and higher.
' FlashForMs will blink light or a flasher for TotalPeriod(ms) at rate of BlinkPeriod(ms)
' When TotalPeriod done, light or flasher will be set to FinalState value where
' Final State values are:   0=Off, 1=On, 2=Return to previous State
'***************************************************************************************************

Sub FlashForMs(MyLight, TotalPeriod, BlinkPeriod, FinalState)

    If TypeName(MyLight) = "Light" Then
        If FinalState = 2 Then
            FinalState = MyLight.State
        End If
        MyLight.BlinkInterval = BlinkPeriod
        MyLight.Duration 2, TotalPeriod, FinalState
    ElseIf TypeName(MyLight) = "Flasher" Then
        Dim steps
        ' Store all blink information
        steps = Int(TotalPeriod / BlinkPeriod + .5) 
        If FinalState = 2 Then                      
            FinalState = ABS(MyLight.Visible)
        End If
        MyLight.UserValue = steps * 10 + FinalState        
        MyLight.TimerInterval = BlinkPeriod
        MyLight.TimerEnabled = 0
        MyLight.TimerEnabled = 1
        ExecuteGlobal "Sub " & MyLight.Name & "_Timer:" & "Dim tmp, steps, fstate:tmp=me.UserValue:fstate = tmp MOD 10:steps= tmp\10 -1:Me.Visible = steps MOD 2:me.UserValue = steps *10 + fstate:If Steps = 0 then Me.Visible = fstate:Me.TimerEnabled=0:End if:End Sub"
    End If
End Sub

'****************************************
' Init table for a new game
'****************************************

Sub ResetForNewGame()
    'debug.print "ResetForNewGame"
    Dim i

    bGameInPLay = True
    bBallSaverActive = False

    StopAttractMode
    GiOn

    CurrentPlayer = 1
    PlayersPlayingGame = 1
    bOnTheFirstBall = True
    For i = 1 To MaxPlayers
        Score(i) = 0
        ExtraBallsAwards(i) = 0
        Special1Awarded(i) = False
        Special2Awarded(i) = False
        Special3Awarded(i) = False
        Special4Awarded(i) = False
        Special5Awarded(i) = False
        BallsRemaining(i) = BallsPerGame
    Next
    BonusMultiplier = 1
    Bonus = 0
    UpdateBallInPlay
	UpdatePlayers
    Clear_Match

    ' init other variables
    Tilt = 0

    ' init game variables
    Game_Init()

    ' start a music?
    ' first ball
    vpmtimer.addtimer 2000, "FirstBall '"
End Sub

Sub FirstBall
    'debug.print "FirstBall"
    ' reset table for a new ball, rise droptargets, etc
    ResetForNewPlayerBall()
    CreateNewBall()
End Sub

' (Re-)init table for a new ball or player

Sub ResetForNewPlayerBall()
    'debug.print "ResetForNewPlayerBall"
    UpdatePlayers
    AddScore 0

    ' reset multiplier to 1x
    BonusMultiplier = 1

    ' turn on lights, and variables
    bExtraBallWonThisBall = False
    ResetNewBallVariables
    ResetNewBallLights
End Sub

' Create new ball

Sub CreateNewBall()
    BallRelease.CreateSizedBallWithMass BallSize / 2, BallMass
    BallsOnPlayfield = BallsOnPlayfield + 1
    UpdateBallInPlay
	vpmtimer.addtimer 1000, "PlaySoundAt SoundFXDOF (""fx_Ballrel"", 104, DOFPulse, DOFContactors), Plunger : BallRelease.Kick 90, 4 '"
End Sub

' player lost the ball

Sub EndOfBall
    'debug.print "EndOfBall"

    ' Lost the first ball, now it cannot accept more players
    bOnTheFirstBall = False
	
	' Bonus Count
	'BonusMultiplier = 2 'test
    If NOT Tilted Then
        Select Case BonusMultiplier
            Case 1:BonusCountTimer.Interval = 150
			Case 2:BonusCountTimer.Interval = 400
		End Select
		CBonus = 0
        BonusCountTimer.Enabled = 1
    Else 
    vpmtimer.addtimer 250, "EndOfBall2 '"
	Playsound"MotorLeer2"
	End If
End Sub

Sub BonusCountTimer_Timer 'The bonus are count when the ball is lost
    'debug.print "BonusCount_Timer"
    If Bonus> 0 Then
		If BonusMultiplier = 1 Then
			CBonus = CBonus + 1
			If CBonus = 5 Then	BonusCountTimer.Interval = BonusCountTimer.Interval + 100
			If CBonus = 6 Then BonusCountTimer.Interval = BonusCountTimer.Interval - 100
		End If
        AddScore 1000 * BonusMultiplier
		If BonusMultiplier = 2 Then PlaySoundAt "fx_bonus", Bumper001
        Bonus = Bonus - 1
        UpdateBonusLights
    Else 
        BonusCountTimer.Enabled = 0
        vpmtimer.addtimer 250, "EndOfBall2 '"
		Playsound"MotorLeer2"
    End If
End Sub

Sub UpdateBonusLights
    Select Case Bonus
        Case 0:BL1K.State = 0:BL2K.State = 0:BL3K.State = 0:BL4K.State = 0:BL5K.State = 0:BL6K.State = 0:BL7K.State = 0:BL8K.State = 0:BL9K.State = 0:BL10K.State = 0
        Case 1:BL1K.State = 1:BL2K.State = 0:BL3K.State = 0:BL4K.State = 0:BL5K.State = 0:BL6K.State = 0:BL7K.State = 0:BL8K.State = 0:BL9K.State = 0:BL10K.State = 0
        Case 2:BL1K.State = 0:BL2K.State = 1:BL3K.State = 0:BL4K.State = 0:BL5K.State = 0:BL6K.State = 0:BL7K.State = 0:BL8K.State = 0:BL9K.State = 0:BL10K.State = 0
        Case 3:BL1K.State = 0:BL2K.State = 0:BL3K.State = 1:BL4K.State = 0:BL5K.State = 0:BL6K.State = 0:BL7K.State = 0:BL8K.State = 0:BL9K.State = 0:BL10K.State = 0
        Case 4:BL1K.State = 0:BL2K.State = 0:BL3K.State = 0:BL4K.State = 1:BL5K.State = 0:BL6K.State = 0:BL7K.State = 0:BL8K.State = 0:BL9K.State = 0:BL10K.State = 0
        Case 5:BL1K.State = 0:BL2K.State = 0:BL3K.State = 0:BL4K.State = 0:BL5K.State = 1:BL6K.State = 0:BL7K.State = 0:BL8K.State = 0:BL9K.State = 0:BL10K.State = 0
        Case 6:BL1K.State = 0:BL2K.State = 0:BL3K.State = 0:BL4K.State = 0:BL5K.State = 0:BL6K.State = 1:BL7K.State = 0:BL8K.State = 0:BL9K.State = 0:BL10K.State = 0
        Case 7:BL1K.State = 0:BL2K.State = 0:BL3K.State = 0:BL4K.State = 0:BL5K.State = 0:BL6K.State = 0:BL7K.State = 1:BL8K.State = 0:BL9K.State = 0:BL10K.State = 0
        Case 8:BL1K.State = 0:BL2K.State = 0:BL3K.State = 0:BL4K.State = 0:BL5K.State = 0:BL6K.State = 0:BL7K.State = 0:BL8K.State = 1:BL9K.State = 0:BL10K.State = 0
        Case 9:BL1K.State = 0:BL2K.State = 0:BL3K.State = 0:BL4K.State = 0:BL5K.State = 0:BL6K.State = 0:BL7K.State = 0:BL8K.State = 0:BL9K.State = 1:BL10K.State = 0
        Case 10:BL1K.State = 0:BL2K.State = 0:BL3K.State = 0:BL4K.State = 0:BL5K.State = 0:BL6K.State = 0:BL7K.State = 0:BL8K.State = 0:BL9K.State = 0:BL10K.State = 1
    End Select
	If BL10K.State = 1 Then
		LTLeft1.State = 1 : LTLeft2.State = 1 : LTLeft3.State = 1 : LTLeft4.State = 1 : LTLeft5.State = 1
	End If
End Sub

Sub EndOfBall2
    'debug.print "EndOfBall2"

    Tilted = False
    Tilt = 0
    TiltReel.SetValue 0
    If B2SOn then
        Controller.B2SSetTilt 0
    end if
    DisableTable False

   ' win extra ball?
    If(ExtraBallsAwards(CurrentPlayer)> 0) Then
        'debug.print "Extra Ball"

        ' if so then give it
        ExtraBallsAwards(CurrentPlayer) = ExtraBallsAwards(CurrentPlayer) - 1

        ' turn off light if no more extra balls
        If(ExtraBallsAwards(CurrentPlayer) = 0) Then
			LightShootAgain.State = 0
			If B2SOn then
				Controller.B2SSetShootAgain 0
			End If
        End If

        ' extra ball sound or light?

        ' reset as in a new ball
        ResetForNewPlayerBall()
        CreateNewBall()

    Else ' no extra ball

        BallsRemaining(CurrentPlayer) = BallsRemaining(CurrentPlayer) - 1

        ' last ball?
        If(BallsRemaining(CurrentPlayer) <= 0) Then
            CheckHighScore()
        End If

        ' this is not the last ball, check for new player
        EndOfBallComplete()
    End If
End Sub

Sub EndOfBallComplete()
    'debug.print "EndOfBallComplete"
    Dim NextPlayer

    ' other players?
    If(PlayersPlayingGame> 1) Then
        NextPlayer = CurrentPlayer + 1
        ' if it is the last player then go to the first one
        If(NextPlayer> PlayersPlayingGame) Then
            NextPlayer = 1
        End If
    Else
        NextPlayer = CurrentPlayer
    End If

    'debug.print "Next Player = " & NextPlayer

    ' end of game?
    If((BallsRemaining(CurrentPlayer) <= 0) AND(BallsRemaining(NextPlayer) <= 0) ) Then

      ' match if playing with coins
        If bFreePlay = False Then
            Verification_Match
        End If

        ' end of game
        EndOfGame()
    Else
        ' next player
        CurrentPlayer = NextPlayer

        ' update score
        AddScore 0

        ' reset table for new player
        ResetForNewPlayerBall()
        CreateNewBall()
    End If
End Sub

' Called at the end of the game

Sub EndOfGame()
    'debug.print "EndOfGame"

    bGameInPLay = False
    bJustStarted = False

    ' turn off flippers
    SolLFlipper 0
    SolRFlipper 0

    ' start the attract mode
    StartAttractMode
End Sub

' Function to calculate the balls left
Function Balls
    Dim tmp
    tmp = BallsPerGame - BallsRemaining(CurrentPlayer) + 1
    If tmp> BallsPerGame Then
        Balls = BallsPerGame
    Else
        Balls = tmp
    End If
End Function

' check the highscore
Sub CheckHighscore
    Dim playertops, si, sj, i, stemp, stempplayers
    For i = 1 to 4
        sortscores(i) = 0
        sortplayers(i) = 0
    Next
    playertops = 0
    For i = 1 to PlayersPlayingGame
        sortscores(i) = Score(i)
        sortplayers(i) = i
    Next
    For si = 1 to PlayersPlayingGame
        For sj = 1 to PlayersPlayingGame-1
            If sortscores(sj)> sortscores(sj + 1) then
                stemp = sortscores(sj + 1)
                stempplayers = sortplayers(sj + 1)
                sortscores(sj + 1) = sortscores(sj)
                sortplayers(sj + 1) = sortplayers(sj)
                sortscores(sj) = stemp
                sortplayers(sj) = stempplayers
            End If
        Next
    Next
    HighScoreTimer.interval = 100
    HighScoreTimer.enabled = True
    ScoreChecker = 4
    CheckAllScores = 1
    NewHighScore sortscores(ScoreChecker), sortplayers(ScoreChecker)
End Sub

'******************
'      Match
'******************

Sub Verification_Match()
    PlaySound "MotorLeer2"
    Match = INT(RND(1) * 10) * 10 ' random between 00 and 90
    Display_Match
    If(Score(CurrentPlayer) MOD 100) = Match Then
        AwardSpecial      
    End If
End Sub

Sub Clear_Match()
    MatchReel1.SetValue 0
    MatchReel2.SetValue 0
    If B2SOn then
        Controller.B2SSetMatch 0
    end if
End Sub

Sub Display_Match()
	If (Match \ 10) < 5 Then  MatchReel1.SetValue 1 + (Match \ 10)  Else  MatchReel2.SetValue 1 + (Match \ 10)
    If B2SOn then
        If Match = 0 then
            Controller.B2SSetMatch 100
        else
            Controller.B2SSetMatch Match
        end if
    end if
End Sub

' *********************************************************************
'                      Drain / Plunger Functions
' *********************************************************************

Sub Drain_Hit()
    Drain.DestroyBall
    BallsOnPlayfield = BallsOnPlayfield - 1
    PlaySoundAt "fx_drain", Drain
	DOF 250, DOFPulse

    'tilted?
    If Tilted Then
        StopEndOfBallMode
    End If

    ' if still playing and not tilted
    If(bGameInPLay = True) AND (Tilted = False) Then

        ' ballsaver?
        If(bBallSaverActive = True) Then
            CreateNewBall()
        Else
            ' last ball?
            If(BallsOnPlayfield = 0) Then
                StopEndOfBallMode
                vpmtimer.addtimer 500, "EndOfBall '" 
                Exit Sub
            End If
        End If
    End If
End Sub

Sub swPlungerRest_Hit()
    bBallInPlungerLane = True
End Sub

Sub swPlungerRest_UnHit()
    bBallInPlungerLane = False
End Sub

' ***************************************
'               Score functions
' ***************************************

Sub AddScore(Points)
    If Tilted Then Exit Sub    
    Select Case Points
        Case 10, 100, 1000', 10000
            Score(CurrentPlayer) = Score(CurrentPlayer) + points
            UpdateScore points
        ' sounds  
			If Points = 100 AND(Score(CurrentPlayer) MOD 1000) \ 100 = 0 Then            ' new reel 1000
                PlaySound SoundFXDOF ("fx_williamschime1000", 303, DOFPulse, DOFChimes)
            ElseIf Points = 10 AND(Score(CurrentPlayer) MOD 100) \ 10 = 0 Then           ' new reel 100
                PlaySound SoundFXDOF ("fx_williamschime100", 302, DOFPulse, DOFChimes)
			ElseIf Points = 10000 Then
                PlaySound SoundFXDOF ("fx_williamschime1000", 303, DOFPulse, DOFChimes)  
			ElseIf Points = 1000 Then
                PlaySound SoundFXDOF ("fx_williamschime1000", 303, DOFPulse, DOFChimes)
			ElseIf Points = 100 Then
                PlaySound SoundFXDOF ("fx_williamschime100", 302, DOFPulse, DOFChimes)          
			Else
                PlaySound SoundFXDOF ("fx_williamschime10", 301, DOFPulse, DOFChimes)
            End If
        Case 20, 30, 40, 50
            Add10 = Add10 + Points \ 10
            AddScore10Timer.Enabled = TRUE 
        Case 200, 300, 400, 500
            Add100 = Add100 + Points \ 100
            AddScore100Timer.Enabled = TRUE 
        Case 2000, 3000, 4000, 5000
            Add1000 = Add1000 + Points \ 1000
            AddScore1000Timer.Enabled = TRUE
        Case 20000, 30000, 40000, 50000
            Add10000 = Add10000 + Points \ 10000
            AddScore10000Timer.Enabled = TRUE
    End Select

    ' check for higher score and specials for 3 Balls
	If BallsPerGame = 3 Then
		If Score(CurrentPlayer) >= Special1 AND Special1Awarded(CurrentPlayer) = False Then
			AwardSpecial
			Special1Awarded(CurrentPlayer) = True
		End If
		If Score(CurrentPlayer) >= Special2 AND Special2Awarded(CurrentPlayer) = False Then
			AwardSpecial
			Special2Awarded(CurrentPlayer) = True
		End If
		If Score(CurrentPlayer) >= Special3 AND Special3Awarded(CurrentPlayer) = False Then
			AwardSpecial
			Special3Awarded(CurrentPlayer) = True
		End If
	End If
   ' check for higher score and specials for 5 Balls
	If BallsPerGame = 5 Then
		If Score(CurrentPlayer) >= Special4 AND Special4Awarded(CurrentPlayer) = False Then
			AwardSpecial
			Special4Awarded(CurrentPlayer) = True
		End If
		If Score(CurrentPlayer) >= Special5 AND Special5Awarded(CurrentPlayer) = False Then
			AwardSpecial
			Special5Awarded(CurrentPlayer) = True
		End If
	End If
End Sub

'************************************
'       Score sound Timers
'************************************

Sub AddScore10Timer_Timer()
    if Add10> 0 then
        AddScore 10
        Add10 = Add10 - 1
    Else
        Me.Enabled = FALSE
    End If
End Sub

Sub AddScore100Timer_Timer()
    if Add100> 0 then
        AddScore 100
        Add100 = Add100 - 1
    Else
        Me.Enabled = FALSE
    End If
End Sub

Sub AddScore1000Timer_Timer()
    if Add1000> 0 then
        AddScore 1000
        Add1000 = Add1000 - 1
    Else
        Me.Enabled = FALSE
    End If
End Sub

Sub AddScore10000Timer_Timer()
    if Add10000> 0 then
        AddScore 10000
        Add10000 = Add10000 - 1
    Else
        Me.Enabled = FALSE
    End If
End Sub

'*******************
'     Bonus
'*******************

Sub AddBonus
    If Tilted Then Exit Sub
	If Bonus < 10 Then
		Bonus = Bonus + 1
		DOF 210, DOFPulse
		vpmtimer.addtimer 200, "UpdateBonusLights '"
    End If
End Sub

'***********************************************************************************
'        Score EM reels - puntuaciones - y actualiza otras luces del backdrop
'***********************************************************************************
'esta es al rutina que actualiza la puntuación del jugador

Sub UpdateScore(playerpoints)
    Select Case CurrentPlayer
        Case 1:ScoreReel1.Addvalue playerpoints
		Case 2:ScoreReel2.Addvalue playerpoints
		Case 3:ScoreReel3.Addvalue playerpoints
		Case 4:ScoreReel4.Addvalue playerpoints
    End Select
    If B2SOn then
        Controller.B2SSetScorePlayer CurrentPlayer, Score(CurrentPlayer)
        If Score(CurrentPlayer) >= 100000 then
            Controller.B2SSetScoreRollover 24 + CurrentPlayer, 1
        end if
    end if
End Sub

Sub ResetScores
    ScoreReel1.ResetToZero
    ScoreReel2.ResetToZero
    ScoreReel3.ResetToZero
    ScoreReel4.ResetToZero
    If B2SOn then
        Controller.B2SSetScorePlayer1 0
        Controller.B2SSetScoreRolloverPlayer1 0
        Controller.B2SSetScorePlayer2 0
        Controller.B2SSetScoreRolloverPlayer2 0
        Controller.B2SSetScorePlayer3 0
        Controller.B2SSetScoreRolloverPlayer3 0
        Controller.B2SSetScorePlayer4 0
        Controller.B2SSetScoreRolloverPlayer4 0
		Controller.B2SSetData 81,0
		Controller.B2SSetData 82,0
		Controller.B2SSetData 83,0
		Controller.B2SSetData 84,0
    end if
End Sub

Sub AddCredits(value) 'limit to 15 credits
    If Credits <15 Then
        Credits = Credits + value
        UpdateCredits
    end if
End Sub

Sub UpdateCredits
    If Credits> 0 Then 'in Bally tables
        CreditLight.State = 1
    Else
        CreditLight.State = 0
    End If
    PlaySound "fx_relay"
    CreditsReel.SetValue Credits
    If B2SOn Then
		If Credits < 10 Then Controller.B2SSetCredits Credits 'limited to 9 for backglass
		If Credits = 0 then
            Controller.B2SSetdata 20,0
        else
            Controller.B2SSetdata 20,1
        end if
    end if
End Sub

Sub UpdateBallInPlay
    Select Case(Balls)
        Case 1:BallInPlayR.SetValue 1
        Case 2:BallInPlayR.SetValue 2
        Case 3:BallInPlayR.SetValue 3
        Case 4:BallInPlayR.SetValue 4
        Case 5:BallInPlayR.SetValue 5
    End Select
    If B2SOn Then
        Controller.B2SSetBallInPlay Balls
    End If
End Sub

Sub UpdatePlayers
    Select case CurrentPlayer
        Case 0:pl1.State = 0:pl2.State = 0:pl3.State = 0:pl4.State = 0
        Case 1:pl1.State = 1:pl2.State = 0:pl3.State = 0:pl4.State = 0
        Case 2:pl1.State = 0:pl2.State = 1:pl3.State = 0:pl4.State = 0
        Case 3:pl1.State = 0:pl2.State = 0:pl3.State = 1:pl4.State = 0
        Case 4:pl1.State = 0:pl2.State = 0:pl3.State = 0:pl4.State = 1
    End Select
    If B2SOn Then	
		Controller.B2SSetPlayerUp CurrentPlayer
		Controller.B2SSetData 81,0
		Controller.B2SSetData 82,0
		Controller.B2SSetData 83,0
		Controller.B2SSetData 84,0
		Controller.B2SSetData 80 + CurrentPlayer,1
    End If
    Select Case PlayersPlayingGame
        Case 0:cp1.State = 0:cp2.State = 0:cp3.State = 0:cp4.State = 0
        Case 1:cp1.State = 1:cp2.State = 0:cp3.State = 0:cp4.State = 0
        Case 2:cp1.State = 0:cp2.State = 1:cp3.State = 0:cp4.State = 0
        Case 3:cp1.State = 0:cp2.State = 0:cp3.State = 1:cp4.State = 0
        Case 4:cp1.State = 0:cp2.State = 0:cp3.State = 0:cp4.State = 1
    End Select
    If B2SOn Then
        Controller.B2SSetCanPlay PlayersPlayingGame
    End If
End Sub


'*************************
'        Specials
'*************************

Sub AwardExtraBall()
    If NOT bExtraBallWonThisBall Then
        ExtraBallsAwards(CurrentPlayer) = ExtraBallsAwards(CurrentPlayer) + 1
        bExtraBallWonThisBall = True
		LightShootAgain.State = 1
        If B2SOn Then
            Controller.B2SSetShootAgain 1
        End If		
    End If
End Sub

Sub AwardSpecial()
    PlaySound SoundfXDOF ("fx_knocker", 110, DOFPulse, DOFKnocker)
    AddCredits 1
End Sub

' ********************************
'        Attract Mode
' ********************************
' use the"Blink Pattern" of each light

Sub StartAttractMode()
    Dim x
	If AttractMode = 1 Then
		bAttractMode = True
		For each x in aLights
			x.State = 2
		Next
	End If
    If B2SOn then
        Controller.B2SSetGameOver 1
        Controller.B2SSetBallInPlay 0
		Controller.B2SSetPlayerUp 0
        Controller.B2SSetCanPlay 1
		Controller.B2SSetTilt 0
		Controller.B2SSetData 81,1
		Controller.B2SSetData 82,1
		Controller.B2SSetData 83,1
		Controller.B2SSetData 84,1
    end if
    GameOverR.SetValue 1
    BallInPlayR.SetValue 0
	pl1.State = 0:pl2.State = 0 : pl3.State = 0:pl4.State = 0
    cp1.State = 1 : cp2.State = 0 : cp3.State = 0 : cp4.State = 0
	TiltReel.SetValue 0	
End Sub

Sub StopAttractMode()
    Dim x
    bAttractMode = False
    TurnOffPlayfieldLights
    ResetScores
    GameOverR.SetValue 0
    If B2SOn then
        Controller.B2SSetGameOver 0
    end if
End Sub

'************************************************
'    Load / Save / Highscore
'************************************************

Sub Loadhs
    ' Based on Black's Highscore routines
    Dim FileObj
    Dim ScoreFile, TextStr
    Dim temp1
    Dim temp2
    Dim temp3
    Dim temp4
    Dim temp5
    Dim temp6
    Dim temp8
    Dim temp9
    Dim temp10
    Dim temp11
    Dim temp12
    Dim temp13
    Dim temp14
    Dim temp15
    Dim temp16
    Dim temp17

    Set FileObj = CreateObject("Scripting.FileSystemObject")
    If Not FileObj.FolderExists(UserDirectory) then
        Credits = 0
        Exit Sub
    End If
    If Not FileObj.FileExists(UserDirectory & TableName& ".txt") then
        Credits = 0
        Exit Sub
    End If
    Set ScoreFile = FileObj.GetFile(UserDirectory & TableName& ".txt")
    Set TextStr = ScoreFile.OpenAsTextStream(1, 0)
    If(TextStr.AtEndOfStream = True) then
        Exit Sub
    End If
    temp1 = TextStr.ReadLine
    temp2 = textstr.readline

    HighScore = cdbl(temp1)
    If HighScore <1 then
        temp8 = textstr.readline
        temp9 = textstr.readline
        temp10 = textstr.readline
        temp11 = textstr.readline
        temp12 = textstr.readline
        temp13 = textstr.readline
        temp14 = textstr.readline
        temp15 = textstr.readline
        temp16 = textstr.readline
        temp17 = textstr.readline
    End If
    TextStr.Close
    Credits = cdbl(temp2)

    If HighScore <1 then
        HSScore(1) = int(temp8)
        HSScore(2) = int(temp9)
        HSScore(3) = int(temp10)
        HSScore(4) = int(temp11)
        HSScore(5) = int(temp12)

        HSName(1) = temp13
        HSName(2) = temp14
        HSName(3) = temp15
        HSName(4) = temp16
        HSName(5) = temp17
    End If
    Set ScoreFile = Nothing
    Set FileObj = Nothing
    SortHighscore 'added to fix a previous error
End Sub

Sub Savehs
    ' Based on Black's Highscore routines
    Dim FileObj
    Dim ScoreFile
    Dim xx
    Set FileObj = CreateObject("Scripting.FileSystemObject")
    If Not FileObj.FolderExists(UserDirectory) then
        Exit Sub
    End If
    Set ScoreFile = FileObj.CreateTextFile(UserDirectory & TableName& ".txt", True)
    ScoreFile.WriteLine 0
    ScoreFile.WriteLine Credits
    For xx = 1 to 5
        scorefile.writeline HSScore(xx)
    Next
    For xx = 1 to 5
        scorefile.writeline HSName(xx)
    Next
    ScoreFile.Close
    Set ScoreFile = Nothing
    Set FileObj = Nothing
End Sub

Sub SortHighscore
    Dim tmp, tmp2, i, j
    For i = 1 to 5
        For j = 1 to 4
            If HSScore(j) <HSScore(j + 1) Then
                tmp = HSScore(j + 1)
                tmp2 = HSName(j + 1)
                HSScore(j + 1) = HSScore(j)
                HSName(j + 1) = HSName(j)
                HSScore(j) = tmp
                HSName(j) = tmp2
            End If
        Next
    Next
End Sub

'****************************************
' Realtime updates
'****************************************

Function PI()
	PI = 4*Atn(1)
End Function

Sub GameTimer_Timer
    RollingUpdate
    LeftFlipperTop.RotZ = LeftFlipper.CurrentAngle
    LeftFlipperTop2.RotZ = LeftFlipper2.CurrentAngle
    RightFlipperTop.RotZ = RightFlipper.CurrentAngle
    Pgate1.rotx = Gate1.currentangle*.6
End Sub

'***********************************************************************
' *********************************************************************
'  *********     G A M E  C O D E  S T A R T S  H E R E      *********
' *********************************************************************
'***********************************************************************

Sub VPObjects_Init 'init objects
    TurnOffPlayfieldLights()
End Sub

' Dim all the variables

Sub Game_Init() 'called at the start of a new game
    'Start music?
    'Init variables?
	AltCounter = 1
    'Start or init timers
    'Init lights?
    TurnOffPlayfieldLights()
End Sub

Sub StopEndOfBallMode() 'called when the last ball is drained

End Sub

Sub ResetNewBallVariables() 'init variables new ball/player	
	CardsRun = 0
	'AltCounter = 1
	Alt2Counter = 0
End Sub

Sub ResetNewBallLights()    'init lights for new ball/player
	TurnOffPlayfieldLights()
	TurnOnNewBallLights()
	Bonus = 1 : UpdateBonusLights()
	Select Case AltCounter
		Case 1 : LTTarget1.State = 1 : LTTarget2.State = 0 : LTTarget3.State = 0 : LTTarget4.State = 0 : LTTarget5.State = 0
		Case 2 : LTTarget1.State = 0 : LTTarget2.State = 1 : LTTarget3.State = 0 : LTTarget4.State = 0 : LTTarget5.State = 0
		Case 3 : LTTarget1.State = 0 : LTTarget2.State = 0 : LTTarget3.State = 1 : LTTarget4.State = 0 : LTTarget5.State = 0
		Case 4 : LTTarget1.State = 0 : LTTarget2.State = 0 : LTTarget3.State = 0 : LTTarget4.State = 1 : LTTarget5.State = 0
		Case 5 : LTTarget1.State = 0 : LTTarget2.State = 0 : LTTarget3.State = 0 : LTTarget4.State = 0 : LTTarget5.State = 1
	End Select
End Sub

Sub TurnOnNewBallLights()
    Dim a
    For each a in aNewBallLights
        a.State = 1
    Next
End Sub

Sub TurnOffPlayfieldLights()
    Dim a
    For each a in aLights
        a.State = 0
    Next
End Sub

' *********************************************************************
'                        Table Object Hit Events
' *********************************************************************
' Any target hit Sub will do this:
' - play a sound
' - do some physical movement
' - add a score, bonus
' - check some variables/modes this trigger is a member of
' - set the "LastSwicthHit" variable in case it is needed later
' *********************************************************************

'**********************
'       Slingshots
'**********************

Dim RStep

Sub RightSlingShot_Slingshot    'right slingshot
    If Tilted Then Exit Sub
    PlaySoundAt SoundFXDOF ("fx_slingshot",104,DOFPulse,DOFcontactors), Remk
    RightSling4.Visible = 1
    Remk.RotX = 26
    RStep = 0
    RightSlingShot.TimerEnabled = True
    ' add points
    AddScore 10
    ' some effect
	Alternate
End Sub

Sub RightSlingShot_Timer
    Select Case RStep
        Case 1:RightSLing4.Visible = 0:RightSLing3.Visible = 1:Remk.RotX = 14
        Case 2:RightSLing3.Visible = 0:RightSLing2.Visible = 1:Remk.RotX = 2
        Case 3:RightSLing2.Visible = 0:Remk.RotX = -20:RightSlingShot.TimerEnabled = 0
    End Select
    RStep = RStep + 1
End Sub

'*********
' Bumpers
'*********

Sub Bumper001_Hit 'Top
    If Tilted Then Exit Sub
    PlaySoundAt SoundFXDOF ("fx_Bumper",105,DOFPulse,DOFContactors), bumper001
    If LightBumper001.State = 1 Then
		AddScore 100 : Alternate
	Else
		Addscore 10 : Alternate2
	End If
End Sub

Sub Bumper002_Hit 'Bottom
    If Tilted Then Exit Sub
    PlaySoundAt SoundFXDOF ("fx_Bumper",106,DOFPulse,DOFContactors), bumper002
    If LightBumper002.State = 1 Then
		AddScore 100 : Alternate
	Else
		Addscore 10 : Alternate2
	End If
End Sub

'*****************
'     Rollover
'*****************

' Out lanes rollover

Sub Trigger001_Hit  'Left
    PlaySoundAt "fx_sensor", Trigger001
	DOF 205, DOFPulse
    If Tilted Then Exit Sub
	If LightSpecial2.State = 1 Then	AwardSpecial
	Addscore 10
End Sub


Sub Trigger002_Hit  'Right
    PlaySoundAt "fx_sensor", Trigger002
	DOF 206, DOFPulse
    If Tilted Then Exit Sub
	Addscore 1000
End Sub

'**********************************
'         Rollover Button
'**********************************

' Top rollover

Sub swTop1_Hit 'left
    PlaySoundAt "fx_sensor", swTop1
    If Tilted Then Exit Sub
 	If LTTop1.State = 1 Then
		Addscore 1000
	Else
		Addscore 100 : Alternate
	End If
End Sub

Sub swTop2_Hit
    PlaySoundAt "fx_sensor", swTop2
    If Tilted Then Exit Sub
 	If LTTop2.State = 1 Then
		Addscore 1000
	Else
		Addscore 100 : Alternate
	End If
End Sub

Sub swTop3_Hit
    PlaySoundAt "fx_sensor", swTop3
    If Tilted Then Exit Sub
 	If LTTop3.State = 1 Then
		Addscore 1000
	Else
		Addscore 100 : Alternate
	End If
End Sub

Sub swTop4_Hit
    PlaySoundAt "fx_sensor", swTop4
    If Tilted Then Exit Sub
 	If LTTop4.State = 1 Then
		Addscore 1000
	Else
		Addscore 100 : Alternate
	End If
End Sub

Sub swTop5_Hit 'right
    PlaySoundAt "fx_sensor", swTop5
    If Tilted Then Exit Sub
 	If LTTop5.State = 1 Then
		Addscore 1000
	Else
		Addscore 100 : Alternate
	End If
End Sub

' Left rollover

Sub swLeft1_Hit 'top
    PlaySoundAt "fx_sensor", swLeft1
    If Tilted Then Exit Sub
 	If LTLeft1.State = 1 Then
		Addscore 100 : Alternate
	Else
		AddBonus
		Addscore 10 : Alternate2
	End If
End Sub

Sub swLeft2_Hit
    PlaySoundAt "fx_sensor", swLeft2
    If Tilted Then Exit Sub
 	If LTLeft2.State = 1 Then
		Addscore 100 : Alternate
	Else
		AddBonus
		Addscore 10 : Alternate2
	End If
End Sub

Sub swLeft3_Hit
    PlaySoundAt "fx_sensor", swLeft3
    If Tilted Then Exit Sub
 	If LTLeft3.State = 1 Then
		Addscore 100 :Alternate
	Else
		AddBonus
		Addscore 10 : Alternate2
	End If
End Sub

Sub swLeft4_Hit
    PlaySoundAt "fx_sensor", swLeft4
    If Tilted Then Exit Sub
 	If LTLeft4.State = 1 Then
		Addscore 100 : Alternate
	Else
		AddBonus
		Addscore 10 : Alternate2
	End If
End Sub

Sub swLeft5_Hit 'bottom
    PlaySoundAt "fx_sensor", swLeft5
    If Tilted Then Exit Sub
 	If LTLeft5.State = 1 Then
		Addscore 100 : Alternate
	Else
		AddBonus
		Addscore 10 : Alternate2
	End If
		
End Sub

' Center rollover

Sub swAce_Hit
    PlaySoundAt "fx_sensor", swAce
    If Tilted Then Exit Sub
	Addscore 10
	LTAce.State = 0
	CheckCards
End Sub

Sub swKing_Hit
    PlaySoundAt "fx_sensor", swKing
    If Tilted Then Exit Sub
	Addscore 10
	LTKing.State = 0
	CheckCards
End Sub

Sub swQueen_Hit
    PlaySoundAt "fx_sensor", swQueen
    If Tilted Then Exit Sub
	Addscore 10
	LTQueen.State = 0
	CheckCards
End Sub

Sub swJack_Hit
    PlaySoundAt "fx_sensor", swJack
    If Tilted Then Exit Sub
	Addscore 10
	LTJack.State = 0
	CheckCards
End Sub

Sub sw10_Hit
    PlaySoundAt "fx_sensor", sw10
    If Tilted Then Exit Sub
	Addscore 10
	LT10.State = 0
	CheckCards
End Sub

'************************
'       Targets
'************************

' Target Top Center

Sub Target1_hit ' Left
    PlaySoundAtBall "fx_target"
	DOF 201, DOFPulse
    If Tilted Then Exit Sub
	If LTTarget1.State = 1 Then Addscore 3000 Else Addscore 50
	If LTTarget1.State = 1 And LightSpecial1.State =1 Then AwardSpecial
End Sub

Sub Target2_hit
    PlaySoundAtBall "fx_target"
	DOF 201, DOFPulse
    If Tilted Then Exit Sub
	If LTTarget2.State = 1 Then Addscore 3000 Else Addscore 50
	If LTTarget2.State = 1 And LightSpecial1.State =1 Then AwardSpecial
End Sub

Sub Target3_hit
    PlaySoundAtBall "fx_target"
	DOF 201, DOFPulse
    If Tilted Then Exit Sub
	If LTTarget3.State = 1 Then Addscore 3000 Else Addscore 50
	If LTTarget3.State = 1 And LightSpecial1.State =1 Then AwardSpecial
End Sub

Sub Target4_hit
    PlaySoundAtBall "fx_target"
	DOF 201, DOFPulse
    If Tilted Then Exit Sub
	If LTTarget4.State = 1 Then Addscore 3000 Else Addscore 50
	If LTTarget4.State = 1 And LightSpecial1.State =1 Then AwardSpecial
End Sub

Sub Target5_hit 'Right
    PlaySoundAtBall "fx_target"
	DOF 201, DOFPulse
    If Tilted Then Exit Sub
	If LTTarget5.State = 1 Then Addscore 3000 Else Addscore 50
	If LTTarget5.State = 1 And LightSpecial1.State =1 Then AwardSpecial
End Sub

' Target Right Joker

Sub TargetJoker1_hit ' Top
    PlaySoundAtBall "fx_target"
	DOF 202, DOFPulse
    If Tilted Then Exit Sub
	LTJoker1.State = 1
	AddScore 1000
	CheckJoker
End Sub

Sub TargetJoker2_hit
    PlaySoundAtBall "fx_target"
	DOF 202, DOFPulse
    If Tilted Then Exit Sub
	LTJoker2.State = 1
	AddScore 1000
	CheckJoker
End Sub

Sub TargetJoker3_hit
    PlaySoundAtBall "fx_target"
	DOF 202, DOFPulse
    If Tilted Then Exit Sub
	LTJoker3.State = 1
	AddScore 1000
	CheckJoker
End Sub

Sub TargetJoker4_hit ' Bottom
    PlaySoundAtBall "fx_target"
	DOF 202, DOFPulse
    If Tilted Then Exit Sub
	LTJoker4.State = 1
	AddScore 1000
	CheckJoker
End Sub

'******************************
'      Extra routines
'******************************

Sub CheckJoker()
	If LightShootAgain.State = 0 Then
		If LTJoker1.State = 1 And LTJoker2.State = 1 And LTJoker3.State = 1 And LTJoker4.State = 1 Then	AwardExtraBall
	End If
End Sub

Sub CheckCards()
    Select Case CardsRun
	Case 0 : 
		If LTAce.State = 0 And LTJack.State = 0 And LTQueen.State = 0 And LTKing.State = 0 And LT10.State = 0 Then	
			LTAce.State = 1 : LTJack.State = 1 : LTQueen.State = 1 : LTKing.State = 1 : LT10.State = 1
			LTTop1.State = 1 : LTTop2.State = 1 : LTTop3.State = 1 : LTTop4.State = 1 : LTTop5.State = 1
			LightBumper001.State = 1 : LightBumper002.State = 1
			CardsRun = 1
		End If
	Case 1 : 
		If LTAce.State = 0 And LTJack.State = 0 And LTQueen.State = 0 And LTKing.State = 0 And LT10.State = 0 Then	
			LTAce.State = 1 : LTJack.State = 1 : LTQueen.State = 1 : LTKing.State = 1 : LT10.State = 1
			LightDoubleBonus.State = 1 : BonusMultiplier = 2
			CardsRun = 2
		End If
	Case 2 : 
		If LTAce.State = 0 And LTJack.State = 0 And LTQueen.State = 0 And LTKing.State = 0 And LT10.State = 0 Then				
			LightSpecial1.State = 1 : LightSpecial2.State = 1
			CardsRun = 3
		End If
	Case 3 :
	End Select 
End Sub

Sub Alternate()
	If AltCounter < 5 Then AltCounter = AltCounter + 1 Else AltCounter = 1
	Select Case AltCounter
	Case 1 : LTTarget1.State = 1 : LTTarget2.State = 0 : LTTarget3.State = 0 : LTTarget4.State = 0 : LTTarget5.State = 0
	Case 2 : LTTarget1.State = 0 : LTTarget2.State = 1 : LTTarget3.State = 0 : LTTarget4.State = 0 : LTTarget5.State = 0
	Case 3 : LTTarget1.State = 0 : LTTarget2.State = 0 : LTTarget3.State = 1 : LTTarget4.State = 0 : LTTarget5.State = 0
	Case 4 : LTTarget1.State = 0 : LTTarget2.State = 0 : LTTarget3.State = 0 : LTTarget4.State = 1 : LTTarget5.State = 0
	Case 5 : LTTarget1.State = 0 : LTTarget2.State = 0 : LTTarget3.State = 0 : LTTarget4.State = 0 : LTTarget5.State = 1
	End Select
End Sub

Sub Alternate2()
	If Alt2Counter < 5 Then 
		Alt2Counter = Alt2Counter + 1
	Else 
		Alt2Counter = 1
		Alternate
	End If	
End Sub

' ============================================================================================
' GNMOD - Multiple High Score Display and Collection
' jpsalas: changed ramps by flashers
' ============================================================================================

Dim EnteringInitials ' Normally zero, set to non-zero to enter initials
EnteringInitials = False
Dim ScoreChecker
ScoreChecker = 0
Dim CheckAllScores
CheckAllScores = 0
Dim sortscores(4)
Dim sortplayers(4)

Dim PlungerPulled
PlungerPulled = 0

Dim SelectedChar   ' character under the "cursor" when entering initials

Dim HSTimerCount   ' Pass counter For HS timer, scores are cycled by the timer
HSTimerCount = 5   ' Timer is initially enabled, it'll wrap from 5 to 1 when it's displayed

Dim InitialString  ' the string holding the player's initials as they're entered

Dim AlphaString    ' A-Z, 0-9, space (_) and backspace (<)
Dim AlphaStringPos ' pointer to AlphaString, move Forward and backward with flipper keys
AlphaString = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_<"

Dim HSNewHigh      ' The new score to be recorded

Dim HSScore(5)     ' High Scores read in from config file
Dim HSName(5)      ' High Score Initials read in from config file

' default high scores, remove this when the scores are available from the config file
HSScore(1) = 15000
HSScore(2) = 14000
HSScore(3) = 13000
HSScore(4) = 12000
HSScore(5) = 11000

HSName(1) = "AAA"
HSName(2) = "ZZZ"
HSName(3) = "XXX"
HSName(4) = "ABC"
HSName(5) = "BBB"

Sub HighScoreTimer_Timer
    If EnteringInitials then
        If HSTimerCount = 1 then
            SetHSLine 3, InitialString & MID(AlphaString, AlphaStringPos, 1)
            HSTimerCount = 2
        Else
            SetHSLine 3, InitialString
            HSTimerCount = 1
        End If
    ElseIf bGameInPlay then
        SetHSLine 1, "HIGH SCORE1"
        SetHSLine 2, HSScore(1)
        SetHSLine 3, HSName(1)
        HSTimerCount = 5 ' set so the highest score will show after the game is over
        HighScoreTimer.enabled = false
    ElseIf CheckAllScores then
        NewHighScore sortscores(ScoreChecker), sortplayers(ScoreChecker)
    Else
        ' cycle through high scores
        HighScoreTimer.interval = 2000
        HSTimerCount = HSTimerCount + 1
        If HsTimerCount> 5 then
            HSTimerCount = 1
        End If
        SetHSLine 1, "HIGH SCORE" + FormatNumber(HSTimerCount, 0)
        SetHSLine 2, HSScore(HSTimerCount)
        SetHSLine 3, HSName(HSTimerCount)
    End If
End Sub

Function GetHSChar(String, Index)
    Dim ThisChar
    Dim FileName
    ThisChar = Mid(String, Index, 1)
    FileName = "PostIt"
    If ThisChar = " " or ThisChar = "" then
        FileName = FileName & "BL"
    ElseIf ThisChar = "<" then
        FileName = FileName & "LT"
    ElseIf ThisChar = "_" then
        FileName = FileName & "SP"
    Else
        FileName = FileName & ThisChar
    End If
    GetHSChar = FileName
End Function

Sub SetHsLine(LineNo, String)
    Dim Letter
    Dim ThisDigit
    Dim ThisChar
    Dim StrLen
    Dim LetterLine
    Dim Index
    Dim StartHSArray
    Dim EndHSArray
    Dim LetterName
    Dim xFor
    StartHSArray = array(0, 1, 12, 22)
    EndHSArray = array(0, 11, 21, 31)
    StrLen = len(string)
    Index = 1

    For xFor = StartHSArray(LineNo) to EndHSArray(LineNo)
        Eval("HS" &xFor).imageA = GetHSChar(String, Index)
        Index = Index + 1
    Next
End Sub

Sub NewHighScore(NewScore, PlayNum)
    If NewScore> HSScore(5) then
        HighScoreTimer.interval = 500
        HSTimerCount = 1
        AlphaStringPos = 1      ' start with first character "A"
        EnteringInitials = true ' intercept the control keys while entering initials
        InitialString = ""      ' initials entered so far, initialize to empty
        SetHSLine 1, "PLAYER " + FormatNumber(PlayNum, 0)
        SetHSLine 2, "ENTER NAME"
        SetHSLine 3, MID(AlphaString, AlphaStringPos, 1)
        HSNewHigh = NewScore
        AwardSpecial
    End If
    ScoreChecker = ScoreChecker-1
    If ScoreChecker = 0 then
        CheckAllScores = 0
    End If
End Sub

Sub CollectInitials(keycode)
    Dim i
    If keycode = LeftFlipperKey Then
        ' back up to previous character
        AlphaStringPos = AlphaStringPos - 1
        If AlphaStringPos <1 then
            AlphaStringPos = len(AlphaString) ' handle wrap from beginning to End
            If InitialString = "" then
                ' Skip the backspace If there are no characters to backspace over
                AlphaStringPos = AlphaStringPos - 1
            End If
        End If
        SetHSLine 3, InitialString & MID(AlphaString, AlphaStringPos, 1)
        PlaySound "sfx_Previous"
    ElseIf keycode = RightFlipperKey Then
        ' advance to Next character
        AlphaStringPos = AlphaStringPos + 1
        If AlphaStringPos> len(AlphaString) or(AlphaStringPos = len(AlphaString) and InitialString = "") then
            ' Skip the backspace If there are no characters to backspace over
            AlphaStringPos = 1
        End If
        SetHSLine 3, InitialString & MID(AlphaString, AlphaStringPos, 1)
        PlaySound "sfx_Next"
    ElseIf keycode = StartGameKey or keycode = PlungerKey Then
        SelectedChar = MID(AlphaString, AlphaStringPos, 1)
        If SelectedChar = "_" then
            InitialString = InitialString & " "
            PlaySound("sfx_Esc")
        ElseIf SelectedChar = "<" then
            InitialString = MID(InitialString, 1, len(InitialString) - 1)
            If len(InitialString) = 0 then
                ' If there are no more characters to back over, don't leave the < displayed
                AlphaStringPos = 1
            End If
            PlaySound("sfx_Esc")
        Else
            InitialString = InitialString & SelectedChar
            PlaySound("sfx_Enter")
        End If
        If len(InitialString) <3 then
            SetHSLine 3, InitialString & SelectedChar
        End If
    End If
    If len(InitialString) = 3 then
        ' save the score
        For i = 5 to 1 step -1
            If i = 1 or(HSNewHigh> HSScore(i) and HSNewHigh <= HSScore(i - 1) ) then
                ' Replace the score at this location
                If i <5 then
                    HSScore(i + 1) = HSScore(i)
                    HSName(i + 1) = HSName(i)
                End If
                EnteringInitials = False
                HSScore(i) = HSNewHigh
                HSName(i) = InitialString
                HSTimerCount = 5
                HighScoreTimer_Timer
                HighScoreTimer.interval = 2000
                PlaySound("fx_Bong")
                Exit Sub
            ElseIf i <5 then
                ' move the score in this slot down by 1, it's been exceeded by the new score
                HSScore(i + 1) = HSScore(i)
                HSName(i + 1) = HSName(i)
            End If
        Next
    End If
End Sub
' End GNMOD