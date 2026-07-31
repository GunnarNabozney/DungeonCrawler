using System;
using System.ComponentModel;
using System.Runtime.InteropServices;

public static class DungeonConsoleNative
{
    private const int STD_INPUT_HANDLE = -10;
    private const int STD_OUTPUT_HANDLE = -11;

    private const ushort KEY_EVENT = 0x0001;
    private const ushort MOUSE_EVENT = 0x0002;
    private const ushort WINDOW_BUFFER_SIZE_EVENT = 0x0004;

    private const uint ENABLE_WINDOW_INPUT = 0x0008;
    private const uint ENABLE_MOUSE_INPUT = 0x0010;
    private const uint ENABLE_QUICK_EDIT_MODE = 0x0040;
    private const uint ENABLE_EXTENDED_FLAGS = 0x0080;
    private const uint ENABLE_VIRTUAL_TERMINAL_PROCESSING = 0x0004;

    private const uint MOUSE_WHEELED = 0x0004;
    private const uint MOUSE_HWHEELED = 0x0008;

    private const uint WAIT_OBJECT_0 = 0x00000000;
    private const uint WAIT_TIMEOUT = 0x00000102;
    private const uint WAIT_FAILED = 0xFFFFFFFF;

    private static readonly object SessionLock = new object();
    private static uint originalInputMode;
    private static IntPtr activeInputHandle = IntPtr.Zero;
    private static bool sessionActive;
    private static bool sessionMouseEnabled;

    [StructLayout(LayoutKind.Sequential)]
    private struct COORD
    {
        public short X;
        public short Y;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct SMALL_RECT
    {
        public short Left;
        public short Top;
        public short Right;
        public short Bottom;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct CONSOLE_SCREEN_BUFFER_INFO
    {
        public COORD Size;
        public COORD CursorPosition;
        public ushort Attributes;
        public SMALL_RECT Window;
        public COORD MaximumWindowSize;
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
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

    [StructLayout(LayoutKind.Sequential)]
    private struct WINDOW_BUFFER_SIZE_RECORD
    {
        public COORD Size;
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

        [FieldOffset(4)]
        public WINDOW_BUFFER_SIZE_RECORD WindowBufferSizeEvent;
    }

    public struct TerminalCapabilities
    {
        public bool IsWindows;
        public bool HasInputConsole;
        public bool HasOutputConsole;
        public bool SupportsKeyboard;
        public bool SupportsMouse;
        public bool SupportsWindowEvents;
        public bool SupportsCursor;
        public bool SupportsColor;
        public bool SupportsBufferedRedraw;
        public bool VirtualTerminalOutputEnabled;
        public int Width;
        public int Height;
        public string Failure;
    }

    public struct InputSample
    {
        public bool HasEvent;
        public bool IsKeyEvent;
        public bool IsMouseEvent;
        public bool IsResizeEvent;

        public bool KeyDown;
        public char KeyChar;
        public ushort VirtualKeyCode;
        public ushort VirtualScanCode;
        public ushort RepeatCount;

        public short X;
        public short Y;
        public uint ButtonState;
        public uint EventFlags;
        public int MouseWheelDelta;

        public short Width;
        public short Height;
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
    private static extern IntPtr GetStdHandle(int standardHandle);

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

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool GetConsoleScreenBufferInfo(
        IntPtr consoleOutput,
        out CONSOLE_SCREEN_BUFFER_INFO consoleScreenBufferInfo
    );

    private static bool IsInvalidHandle(IntPtr handle)
    {
        return handle == IntPtr.Zero || handle == new IntPtr(-1);
    }

    public static TerminalCapabilities DetectCapabilities()
    {
        TerminalCapabilities capabilities = new TerminalCapabilities();
        capabilities.IsWindows =
            Environment.OSVersion.Platform == PlatformID.Win32NT;
        capabilities.Failure = String.Empty;

        if (!capabilities.IsWindows)
        {
            capabilities.Failure = "Windows console APIs are unavailable.";
            return capabilities;
        }

        try
        {
            IntPtr inputHandle = GetStdHandle(STD_INPUT_HANDLE);
            IntPtr outputHandle = GetStdHandle(STD_OUTPUT_HANDLE);
            uint inputMode = 0;
            uint outputMode = 0;

            capabilities.HasInputConsole =
                !IsInvalidHandle(inputHandle) &&
                GetConsoleMode(inputHandle, out inputMode);

            capabilities.HasOutputConsole =
                !IsInvalidHandle(outputHandle) &&
                GetConsoleMode(outputHandle, out outputMode);

            capabilities.SupportsKeyboard =
                capabilities.HasInputConsole;
            capabilities.SupportsMouse =
                capabilities.HasInputConsole;
            capabilities.SupportsWindowEvents =
                capabilities.HasInputConsole;
            capabilities.SupportsCursor =
                capabilities.HasOutputConsole;
            capabilities.SupportsColor =
                capabilities.HasOutputConsole;
            capabilities.SupportsBufferedRedraw =
                capabilities.HasOutputConsole;

            if (capabilities.HasOutputConsole)
            {
                capabilities.VirtualTerminalOutputEnabled =
                    (outputMode & ENABLE_VIRTUAL_TERMINAL_PROCESSING) != 0;

                CONSOLE_SCREEN_BUFFER_INFO bufferInfo;

                if (GetConsoleScreenBufferInfo(
                    outputHandle,
                    out bufferInfo
                ))
                {
                    capabilities.Width =
                        bufferInfo.Window.Right -
                        bufferInfo.Window.Left + 1;

                    capabilities.Height =
                        bufferInfo.Window.Bottom -
                        bufferInfo.Window.Top + 1;
                }
            }

            if (!capabilities.HasInputConsole &&
                !capabilities.HasOutputConsole)
            {
                capabilities.Failure =
                    "Standard input and output are not attached to a console.";
            }
            else if (!capabilities.HasInputConsole)
            {
                capabilities.Failure =
                    "Standard input is not attached to a console.";
            }
            else if (!capabilities.HasOutputConsole)
            {
                capabilities.Failure =
                    "Standard output is not attached to a console.";
            }
        }
        catch (Exception exception)
        {
            capabilities.Failure = exception.Message;
        }

        return capabilities;
    }

    public static bool TryEnableVirtualTerminalOutput()
    {
        if (Environment.OSVersion.Platform != PlatformID.Win32NT)
        {
            return false;
        }

        IntPtr outputHandle = GetStdHandle(STD_OUTPUT_HANDLE);
        uint outputMode;

        if (IsInvalidHandle(outputHandle) ||
            !GetConsoleMode(outputHandle, out outputMode))
        {
            return false;
        }

        if ((outputMode & ENABLE_VIRTUAL_TERMINAL_PROCESSING) != 0)
        {
            return true;
        }

        return SetConsoleMode(
            outputHandle,
            outputMode | ENABLE_VIRTUAL_TERMINAL_PROCESSING
        );
    }

    public static IntPtr BeginInputSession(bool enableMouse)
    {
        lock (SessionLock)
        {
            if (sessionActive)
            {
                if (enableMouse && !sessionMouseEnabled)
                {
                    throw new InvalidOperationException(
                        "The active console input session does not include mouse events."
                    );
                }

                return activeInputHandle;
            }

            IntPtr inputHandle = GetStdHandle(STD_INPUT_HANDLE);

            if (IsInvalidHandle(inputHandle))
            {
                throw new Win32Exception(
                    Marshal.GetLastWin32Error(),
                    "Could not obtain the console input handle."
                );
            }

            if (!GetConsoleMode(inputHandle, out originalInputMode))
            {
                throw new Win32Exception(
                    Marshal.GetLastWin32Error(),
                    "Could not read the console input mode."
                );
            }

            uint inputMode =
                originalInputMode |
                ENABLE_WINDOW_INPUT |
                ENABLE_EXTENDED_FLAGS;

            if (enableMouse)
            {
                inputMode |= ENABLE_MOUSE_INPUT;
                inputMode &= ~ENABLE_QUICK_EDIT_MODE;
            }

            if (!SetConsoleMode(inputHandle, inputMode))
            {
                throw new Win32Exception(
                    Marshal.GetLastWin32Error(),
                    "Could not enable raw console input."
                );
            }

            activeInputHandle = inputHandle;
            sessionActive = true;
            sessionMouseEnabled = enableMouse;
            return inputHandle;
        }
    }

    public static IntPtr BeginMouseSession()
    {
        IntPtr inputHandle = BeginInputSession(true);

        if (!FlushConsoleInputBuffer(inputHandle))
        {
            EndInputSession(inputHandle);

            throw new Win32Exception(
                Marshal.GetLastWin32Error(),
                "Could not clear the console input buffer."
            );
        }

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
                    sample.VirtualScanCode =
                        inputRecord.KeyEvent.VirtualScanCode;
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

                    if ((sample.EventFlags & MOUSE_WHEELED) != 0 ||
                        (sample.EventFlags & MOUSE_HWHEELED) != 0)
                    {
                        sample.MouseWheelDelta =
                            (short)((sample.ButtonState >> 16) & 0xFFFF);
                    }

                    return sample;
                }

                if (inputRecord.EventType == WINDOW_BUFFER_SIZE_EVENT)
                {
                    sample.HasEvent = true;
                    sample.IsResizeEvent = true;
                    sample.Width =
                        inputRecord.WindowBufferSizeEvent.Size.X;
                    sample.Height =
                        inputRecord.WindowBufferSizeEvent.Size.Y;
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

    public static void EndInputSession(IntPtr inputHandle)
    {
        lock (SessionLock)
        {
            if (!sessionActive)
            {
                return;
            }

            IntPtr handleToRestore = activeInputHandle;

            if (!SetConsoleMode(handleToRestore, originalInputMode))
            {
                int errorCode = Marshal.GetLastWin32Error();
                sessionActive = false;
                sessionMouseEnabled = false;
                activeInputHandle = IntPtr.Zero;

                throw new Win32Exception(
                    errorCode,
                    "Could not restore the console input mode."
                );
            }

            sessionActive = false;
            sessionMouseEnabled = false;
            activeInputHandle = IntPtr.Zero;
        }
    }

    public static void EndMouseSession(IntPtr inputHandle)
    {
        EndInputSession(inputHandle);
    }
}