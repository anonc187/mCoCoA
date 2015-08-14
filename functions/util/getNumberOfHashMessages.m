function total = getNumberOfHashMessages()

% table = org.anon.cocoa.messages.HashMessage.getCount();
% values = table.values();
% 
% total = 0;
% iter = values.iterator;
% 
% while iter.hasNext()
%     total = total + iter.next();
% end

total = org.anon.cocoa.agents.AbstractSolverAgent.getTotalSentMessages;