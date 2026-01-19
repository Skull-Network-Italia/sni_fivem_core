CreateThread(function()
  -- Attende che il client sia pronto
  while not NetworkIsSessionStarted() do
    Wait(0)
  end

  -- Chiude forzatamente la loadscreen
  ShutdownLoadingScreenNui()
  ShutdownLoadingScreen()
end)
