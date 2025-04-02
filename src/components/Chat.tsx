import React, { useState, useRef, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { Send, ArrowLeft, WifiOff, Bot, Loader2, Sparkles } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import { useBFFStore } from '../lib/store';
import { sendMessageToRasa } from '../lib/rasaProxy';
import { Message } from '../types';
import { MessageBubble } from './MessageBubble';
import { RestaurantSetup } from './RestaurantSetup';
import { LanguageSwitcher } from './LanguageSwitcher';
import { getTranslation } from '../lib/translations';
import { toast } from 'sonner';

export function Chat() {
  const { 
    messages, 
    addMessage, 
    currentLanguage,
    isTyping,
    setTyping,
    restaurantContext
  } = useBFFStore();
  
  const [input, setInput] = useState('');
  const [showSetup, setShowSetup] = useState(!restaurantContext);
  const [connectionError, setConnectionError] = useState(false);
  const [retrying, setRetrying] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
    inputRef.current?.focus();
  }, [messages]);

  const handleSend = async () => {
    if (!input.trim() || isTyping) return;

    const userMessage: Message = {
      id: crypto.randomUUID(),
      content: input,
      sender: 'user',
      timestamp: new Date(),
      language: currentLanguage
    };

    addMessage(userMessage);
    setInput('');
    setTyping(true);
    setConnectionError(false);
    setRetrying(false);

    try {
      const sessionId = crypto.randomUUID();
      const context = {
        messages: messages.slice(-5).map(m => ({
          content: m.content,
          sender: m.sender,
          timestamp: m.timestamp
        }))
      };

      const responses = await sendMessageToRasa(input, sessionId, context);

      for (const response of responses) {
        if (response.custom?.error) {
          setConnectionError(true);
        }
        if (response.custom?.source === 'openai') {
          setRetrying(true);
        }

        const aiMessage: Message = {
          id: crypto.randomUUID(),
          content: response.text,
          sender: 'ai',
          timestamp: new Date(),
          language: currentLanguage,
          custom: response.custom
        };

        addMessage(aiMessage);
      }
    } catch (error) {
      console.error('Error in chat flow:', error);
      setConnectionError(true);
      
      addMessage({
        id: crypto.randomUUID(),
        content: "I apologize, but I'm having trouble connecting right now. Please try again in a moment.",
        sender: 'ai',
        timestamp: new Date(),
        language: currentLanguage,
        custom: { error: true }
      });
    } finally {
      setTyping(false);
      inputRef.current?.focus();
    }
  };

  if (showSetup) {
    return <RestaurantSetup onComplete={() => setShowSetup(false)} />;
  }

  return (
    <div className="flex flex-col h-screen bg-surface-50">
      <div className="flex items-center justify-between p-4 bg-white border-b border-surface-200">
        <Link
          to="/"
          className="flex items-center gap-2 text-brick-950/60 hover:text-brick-600"
        >
          <ArrowLeft className="w-5 h-5" />
          Back
        </Link>
        <motion.div 
          className="flex items-center gap-4"
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
        >
          <div className="flex items-center gap-2">
            <Bot className="w-8 h-8 text-brick-500" />
            <motion.div
              animate={{ 
                scale: [1, 1.1, 1],
                rotate: [0, -5, 5, -5, 0]
              }}
              transition={{ 
                duration: 2,
                repeat: Infinity,
                repeatType: "reverse"
              }}
            >
              <Sparkles className="w-5 h-5 text-gold-500" />
            </motion.div>
            <span className="font-medium">Brick</span>
          </div>
          {retrying && (
            <span className="text-sm text-amber-600 flex items-center gap-1">
              <Loader2 className="w-4 h-4 animate-spin" />
              Using backup system
            </span>
          )}
          <LanguageSwitcher />
        </motion.div>
      </div>

      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {connectionError && (
          <motion.div 
            initial={{ opacity: 0, y: -20 }}
            animate={{ opacity: 1, y: 0 }}
            className="flex items-center justify-center gap-2 p-4 bg-red-50 text-red-600 rounded-lg"
          >
            <WifiOff className="w-5 h-5" />
            <span>Connection issues - retrying with backup system</span>
          </motion.div>
        )}
        
        {messages.map((message, index) => (
          <motion.div
            key={message.id}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: index * 0.1 }}
          >
            <MessageBubble message={message} />
          </motion.div>
        ))}
        <div ref={messagesEndRef} />
      </div>

      <motion.div 
        className="p-4 bg-white border-t border-surface-200"
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
      >
        <div className="flex items-center gap-2">
          <input
            ref={inputRef}
            type="text"
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyPress={(e) => e.key === 'Enter' && !isTyping && handleSend()}
            placeholder={getTranslation(currentLanguage, 'askAboutMenu')}
            className="input-field flex-1"
            disabled={isTyping}
          />
          <motion.button
            onClick={handleSend}
            disabled={isTyping}
            className="btn-primary p-3 disabled:opacity-50"
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
          >
            {isTyping ? (
              <Loader2 className="w-5 h-5 animate-spin" />
            ) : (
              <Send className="w-5 h-5" />
            )}
          </motion.button>
        </div>
      </motion.div>
    </div>
  );
}