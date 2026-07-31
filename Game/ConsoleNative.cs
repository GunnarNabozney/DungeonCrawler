using System;
using System.ComponentModel;
using System.Runtime.InteropServices;

public static class DungeonConsoleNative
{
    private const int STD_INPUT_HANDLE = -10;

    private const ushort KEY_EVENT = 0x0001;
    private const ushort MOUSE_EVENT = 0x0002;

    private const uint ENABLE_WINDOW_INPUT = 0x0008;
    private const uint ENABLE_MOUSE_INPUT = 0x0010;
    private const uint ENABLE_QUICK_EDIT_MODE = 0x0040;
    private const uint ENABLE_EXTENDED_FLAGS = 0x0080;

    private const uint WAIT_OBJECT_0 = 0x00000000;
    private const uint WAIT_TIMEOUT = 0x00000102;
    private const uint WAIT_FAILED = 0xFFFFFFFF;

    private static uint originalMode;
    private static bool sessionActive;

    [StructLayout(LayoutKind.Sequential)]
    private struct COORD
    {
        public short X;
        public short Y;
    }

    [StructLayout(
        LayoutKind.Sequential,
        CharSet = CharSet.Unicode
    )]
    private struct KEY_EVENT_RECORD
    {
        public int KeyDown;
        public ushort RepeatCount;
        public ushort VirtualKeyCode;
        public ushort VirtualScanCode;
        public char UnicodeChar;
        public uint ControlKeyState;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct MOUSE_EVENT_RECORD
    {
        public COORD MousePosition;
        public uint ButtonState;
        public uint ControlKeyState;
        public uint EventFlags;
    }

    [StructLayout(LayoutKind.Explicit, Size = 20)]
    private struct INPUT_RECORD
    {
        [FieldOffset(0)]
        public ushort EventType;

        [FieldOffset(4)]
        public KEY_EVENT_RECORD KeyEvent;

        [FieldOffset(4)]
        public MOUSE_EVENT_RECORD MouseEvent;
    }

    public struct InputSample
    {
        public bool HasEvent;
        public bool IsKeyEvent;
        public bool IsMouseEvent;

        public bool KeyDown;
        public char KeyChar;
        public ushort VirtualKeyCode;
        public ushort RepeatCount;

        public short X;
        public short Y;
        public uint ButtonState;
        public uint EventFlags;
        public uint ControlKeyState;
    }

    public struct MouseSample
    {
        public bool HasEvent;
        public short X;
        public short Y;
        public uint ButtonState;
        public uint EventFlags;
    }

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern IntPtr GetStdHandle(
        int standardHandle
    );

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool GetConsoleMode(
        IntPtr consoleHandle,
        out uint consoleMode
    );

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool SetConsoleMode(
        IntPtr consoleHandle,
        uint consoleMode
    );

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool FlushConsoleInputBuffer(
        IntPtr consoleInput
    );

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern uint WaitForSingleObject(
        IntPtr handle,
        uint milliseconds
    );

    [DllImport(
        "kernel32.dll",
        CharSet = CharSet.Unicode,
        SetLastError = true
    )]
    private static extern bool ReadConsoleInputW(
        IntPtr consoleInput,
        [Out] INPUT_RECORD[] inputBuffer,
        uint inputBufferLength,
        out uint eventsRead
    );

    public static IntPtr BeginMouseSession()
    {
        IntPtr inputHandle = GetStdHandle(STD_INPUT_HANDLE);

        if (
            inputHandle == IntPtr.Zero ||
            inputHandle == new IntPtr(-1)
        )
        {
            throw new Win32Exception(
                Marshal.GetLastWin32Error(),
                "Could not obtain the console input handle."
            );
        }

        if (!GetConsoleMode(inputHandle, out originalMode))
        {
            throw new Win32Exception(
                Marshal.GetLastWin32Error(),
                "Could not read the console input mode."
            );
        }

        uint mouseMode =
            (
                originalMode |
                ENABLE_WINDOW_INPUT |
                ENABLE_MOUSE_INPUT |
                ENABLE_EXTENDED_FLAGS
            )
            & ~ENABLE_QUICK_EDIT_MODE;

        if (!SetConsoleMode(inputHandle, mouseMode))
        {
            throw new Win32Exception(
                Marshal.GetLastWin32Error(),
                "Could not enable console mouse input."
            );
        }

        if (!FlushConsoleInputBuffer(inputHandle))
        {
            SetConsoleMode(inputHandle, originalMode);

            throw new Win32Exception(
                Marshal.GetLastWin32Error(),
                "Could not clear the console input buffer."
            );
        }

        sessionActive = true;

        return inputHandle;
    }

    public static InputSample ReadInputEvent(
        IntPtr inputHandle,
        uint timeoutMilliseconds
    )
    {
        InputSample sample = new InputSample();

        DateTime deadline =
            DateTime.UtcNow.AddMilliseconds(timeoutMilliseconds);

        uint remaining = timeoutMilliseconds;

        while (true)
        {
            uint waitResult =
                WaitForSingleObject(inputHandle, remaining);

            if (waitResult == WAIT_TIMEOUT)
            {
                return sample;
            }

            if (waitResult == WAIT_FAILED)
            {
                throw new Win32Exception(
                    Marshal.GetLastWin32Error(),
                    "Could not wait for console input."
                );
            }

            if (waitResult != WAIT_OBJECT_0)
            {
                return sample;
            }

            INPUT_RECORD[] inputBuffer = new INPUT_RECORD[1];
            uint eventsRead;

            if (!ReadConsoleInputW(
                inputHandle,
                inputBuffer,
                1,
                out eventsRead
            ))
            {
                throw new Win32Exception(
                    Marshal.GetLastWin32Error(),
                    "Could not read console input."
                );
            }

            if (eventsRead > 0)
            {
                INPUT_RECORD inputRecord = inputBuffer[0];

                if (inputRecord.EventType == KEY_EVENT)
                {
                    sample.HasEvent = true;
                    sample.IsKeyEvent = true;
                    sample.KeyDown =
                        inputRecord.KeyEvent.KeyDown != 0;

                    sample.KeyChar =
                        inputRecord.KeyEvent.UnicodeChar;

                    sample.VirtualKeyCode =
                        inputRecord.KeyEvent.VirtualKeyCode;

                    sample.RepeatCount =
                        inputRecord.KeyEvent.RepeatCount;

                    sample.ControlKeyState =
                        inputRecord.KeyEvent.ControlKeyState;

                    return sample;
                }

                if (inputRecord.EventType == MOUSE_EVENT)
                {
                    sample.HasEvent = true;
                    sample.IsMouseEvent = true;
                    sample.X =
                        inputRecord.MouseEvent.MousePosition.X;

                    sample.Y =
                        inputRecord.MouseEvent.MousePosition.Y;

                    sample.ButtonState =
                        inputRecord.MouseEvent.ButtonState;

                    sample.EventFlags =
                        inputRecord.MouseEvent.EventFlags;

                    sample.ControlKeyState =
                        inputRecord.MouseEvent.ControlKeyState;

                    return sample;
                }
            }

            double remainingMilliseconds =
                (deadline - DateTime.UtcNow).TotalMilliseconds;

            if (remainingMilliseconds <= 0)
            {
                return sample;
            }

            remaining =
                (uint)Math.Ceiling(remainingMilliseconds);
        }
    }

    public static MouseSample ReadMouseEvent(
        IntPtr inputHandle,
        uint timeoutMilliseconds
    )
    {
        MouseSample sample = new MouseSample();

        DateTime deadline =
            DateTime.UtcNow.AddMilliseconds(timeoutMilliseconds);

        uint remaining = timeoutMilliseconds;

        while (true)
        {
            InputSample inputSample =
                ReadInputEvent(inputHandle, remaining);

            if (!inputSample.HasEvent)
            {
                return sample;
            }

            if (inputSample.IsMouseEvent)
            {
                sample.HasEvent = true;
                sample.X = inputSample.X;
                sample.Y = inputSample.Y;
                sample.ButtonState = inputSample.ButtonState;
                sample.EventFlags = inputSample.EventFlags;
                return sample;
            }

            double remainingMilliseconds =
                (deadline - DateTime.UtcNow).TotalMilliseconds;

            if (remainingMilliseconds <= 0)
            {
                return sample;
            }

            remaining =
                (uint)Math.Ceiling(remainingMilliseconds);
        }
    }

    public static void EndMouseSession(
        IntPtr inputHandle
    )
    {
        if (!sessionActive)
        {
            return;
        }

        SetConsoleMode(inputHandle, originalMode);
        sessionActive = false;
    }
}